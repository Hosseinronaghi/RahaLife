import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/ai_provider.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});
  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  AiProviderType provider = AiProviderType.rahaFree;
  final apiKeyController = TextEditingController();
  final baseUrlController = TextEditingController();

  @override
  void dispose() {
    apiKeyController.dispose();
    baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final personal = provider != AiProviderType.rahaFree;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiAssistant)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<AiProviderType>(
          value: provider,
          decoration: InputDecoration(labelText: l10n.aiAssistant),
          items: const [
            DropdownMenuItem(value: AiProviderType.rahaFree, child: Text('Raha Free AI')),
            DropdownMenuItem(value: AiProviderType.openAi, child: Text('OpenAI API')),
            DropdownMenuItem(value: AiProviderType.gemini, child: Text('Google Gemini API')),
            DropdownMenuItem(value: AiProviderType.customOpenAiCompatible, child: Text('Custom OpenAI-compatible')),
          ],
          onChanged: (value) => setState(() => provider = value ?? provider),
        ),
        if (personal) ...[
          const SizedBox(height: 16),
          TextField(controller: apiKeyController, obscureText: true, decoration: const InputDecoration(labelText: 'API Key')),
        ],
        if (provider == AiProviderType.customOpenAiCompatible) ...[
          const SizedBox(height: 16),
          TextField(controller: baseUrlController, decoration: const InputDecoration(labelText: 'Base URL')),
        ],
        const SizedBox(height: 16),
        const Card(child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('ChatGPT subscriptions and OpenAI API billing are separate. This app connects through supported APIs only.'),
        )),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.link), label: const Text('Test connection')),
      ]),
    );
  }
}
