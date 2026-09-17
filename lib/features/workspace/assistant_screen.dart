import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../ai/data/openai_compatible_provider.dart';
import '../ai/data/secure_ai_credentials.dart';
import '../ai/domain/ai_provider.dart';
import '../../core/persistence/drift_entity_repository.dart';
import '../sync/presentation/synced_feature_refresh.dart';
import 'record_editor.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});
  @override
  ConsumerState<AssistantScreen> createState() => _AssistantState();
}

class _AssistantState extends ConsumerState<AssistantScreen> {
  final prompt = TextEditingController();
  String answer = '', error = '';
  bool busy = false, applied = false;
  List<Map<String, Object?>> proposals = [];
  @override
  void dispose() {
    prompt.dispose();
    super.dispose();
  }

  Future<void> ask() async {
    if (prompt.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      error = '';
      proposals = [];
      applied = false;
    });
    try {
      final settings = await SharedPreferences.getInstance();
      final kind = settings.getString('ai.provider') ?? 'rahaFree';
      if (kind == 'rahaFree') {
        throw StateError(
          'Select your AI provider in settings. Free Raha service has not been configured.',
        );
      }
      final key = await SecureAiCredentials().readApiKey(kind);
      if (key == null || key.isEmpty) {
        throw StateError('Add your API key in settings.');
      }
      final model = settings.getString('ai.model') ?? 'gpt-4.1-mini';
      const system =
          'You are a personal organizer. Reply in the user language. Do not prescribe medication or make financial transactions. For explicitly requested task creation, return a JSON object with answer and tasks (maximum 10), each with title and dateTime in ISO 8601. Never propose deletion or modification of existing records. Otherwise respond with plain text.';
      String result;
      if (kind == 'gemini') {
        final response =
            await Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 60),
              ),
            ).post<Map<String, dynamic>>(
              'https://generativelanguage.googleapis.com/v1beta/models/${Uri.encodeComponent(model)}:generateContent',
              options: Options(headers: {'x-goog-api-key': key}),
              data: {
                'system_instruction': {
                  'parts': [
                    {'text': system},
                  ],
                },
                'contents': [
                  {
                    'parts': [
                      {'text': prompt.text.trim()},
                    ],
                  },
                ],
              },
            );
        result =
            (((response.data?['candidates'] as List?)?.firstOrNull
                        as Map?)?['content']?['parts']
                    as List?)
                ?.map((e) => e['text'] ?? '')
                .join('\n') ??
            '';
      } else {
        final base = kind == 'openAi'
            ? 'https://api.openai.com/v1'
            : settings.getString('ai.baseUrl') ?? '';
        final uri = Uri.tryParse(base);
        if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
          throw StateError('AI requires a valid HTTPS endpoint.');
        }
        final response = await OpenAiCompatibleProvider(
          apiKey: key,
          model: model,
          baseUrl: base,
        ).generate(AiRequest(prompt: prompt.text.trim(), systemPrompt: system));
        result = response.text;
      }
      final clean = result
          .replaceAll(RegExp(r'^```(?:json)?\s*|\s*```$'), '')
          .trim();
      try {
        final decoded = jsonDecode(clean);
        if (decoded is Map) {
          answer = decoded['answer']?.toString() ?? '';
          proposals = (decoded['tasks'] as List? ?? [])
              .whereType<Map>()
              .take(10)
              .map((e) => Map<String, Object?>.from(e))
              .where(
                (e) =>
                    (e['title']?.toString().trim().isNotEmpty ?? false) &&
                    DateTime.tryParse(e['dateTime']?.toString() ?? '') != null,
              )
              .toList();
        } else {
          answer = result;
        }
      } catch (_) {
        answer = result;
      }
      if (mounted) setState(() => busy = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(tr(c, 'دستیار برنامه‌ریزی', 'Planning assistant')),
      actions: [
        IconButton(
          onPressed: () => c.push('/settings/ai'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              tr(
                c,
                'فقط متن این درخواست برای سرویس انتخاب‌شده ارسال می‌شود. ایجاد برنامه پس از دیدن پیش‌نمایش و تأیید تو انجام می‌شود.',
                'Only this prompt is sent to your selected provider. Plans are created after you review and confirm them.',
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: prompt,
          minLines: 3,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: tr(c, 'چه کمکی می‌خواهی؟', 'How can I help?'),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: busy ? null : ask,
          icon: Icon(busy ? Icons.hourglass_top : Icons.auto_awesome),
          label: Text(tr(c, 'ارسال درخواست', 'Send prompt')),
        ),
        if (error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              error,
              style: TextStyle(color: Theme.of(c).colorScheme.error),
            ),
          ),
        if (answer.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: SelectableText(answer),
          ),
        for (final item in proposals)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.event_available),
              title: Text(item['title'].toString()),
              subtitle: Text(item['dateTime'].toString()),
            ),
          ),
        if (proposals.isNotEmpty)
          FilledButton(
            onPressed: applied
                ? null
                : () async {
                    final repo = DriftEntityRepository();
                    await repo.db.transaction(() async {
                      for (final e in proposals) {
                        await repo.upsert('home_entry', {
                          'id': const Uuid().v4(),
                          'type': 'affair',
                          'title': e['title'],
                          'dateTime': e['dateTime'],
                          'completed': false,
                        });
                      }
                    });
                    invalidateSyncedFeatureProviders(ref);
                    if (mounted) setState(() => applied = true);
                  },
            child: Text(
              applied
                  ? tr(c, 'برنامه‌ها اضافه شدند', 'Plans added')
                  : tr(
                      c,
                      'تأیید و افزودن این برنامه‌ها',
                      'Confirm and add these plans',
                    ),
            ),
          ),
      ],
    ),
  );
}
