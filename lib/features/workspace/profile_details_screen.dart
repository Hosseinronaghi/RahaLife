import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persistence/drift_entity_repository.dart';
import 'record_editor.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({super.key});
  @override
  ConsumerState<ProfileDetailsScreen> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<ProfileDetailsScreen> {
  final name = TextEditingController(), occupation = TextEditingController();
  String style = 'mixed', avatar = '🌿';
  bool loaded = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data =
        await DriftEntityRepository().loadOne('user_preferences', 'profile') ??
        {};
    if (mounted) {
      setState(() {
        name.text = data['name']?.toString() ?? '';
        occupation.text = data['occupation']?.toString() ?? '';
        style = data['style']?.toString() ?? 'mixed';
        avatar = data['avatar']?.toString() ?? '🌿';
        loaded = true;
      });
    }
  }

  @override
  void dispose() {
    name.dispose();
    occupation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(tr(c, 'پروفایل و سبک استفاده', 'Profile & preferences')),
    ),
    body: !loaded
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: Text(avatar, style: const TextStyle(fontSize: 64))),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  for (final item in [
                    '🌿',
                    '🌻',
                    '🎸',
                    '🦊',
                    '🧑',
                    '👩',
                    '🌙',
                    '🪴',
                  ])
                    ActionChip(
                      label: Text(item),
                      onPressed: () => setState(() => avatar = item),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: tr(c, 'نام نمایشی', 'Display name'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: occupation,
                decoration: InputDecoration(
                  labelText: tr(
                    c,
                    'شغل یا حوزهٔ فعالیت',
                    'Occupation or activity',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: style,
                decoration: InputDecoration(
                  labelText: tr(c, 'سبک استفاده', 'Use style'),
                ),
                items:
                    [
                          ('personal', 'شخصی', 'Personal'),
                          ('work', 'کاری', 'Work'),
                          ('study', 'تحصیلی', 'Study'),
                          ('family', 'خانوادگی', 'Family'),
                          ('mixed', 'ترکیبی', 'Mixed'),
                        ]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.$1,
                            child: Text(tr(c, e.$2, e.$3)),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => style = v!),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  await DriftEntityRepository().upsert('user_preferences', {
                    'id': 'profile',
                    'name': name.text.trim(),
                    'occupation': occupation.text.trim(),
                    'style': style,
                    'avatar': avatar,
                  });
                  if (c.mounted) {
                    ScaffoldMessenger.of(c).showSnackBar(
                      SnackBar(
                        content: Text(
                          tr(c, 'پروفایل ذخیره شد', 'Profile saved'),
                        ),
                      ),
                    );
                  }
                },
                child: Text(tr(c, 'ذخیره', 'Save')),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.dashboard_customize_outlined),
                label: Text(
                  tr(
                    c,
                    'اعمال چیدمان پیشنهادی برای این سبک',
                    'Apply suggested home layout',
                  ),
                ),
                onPressed: () async {
                  final slots = switch (style) {
                    'work' => [
                      'projects',
                      'appointments',
                      'affairs',
                      'notes',
                      'finance',
                      'people',
                    ],
                    'study' => [
                      'affairs',
                      'habits',
                      'notes',
                      'projects',
                      'appointments',
                      'inbox',
                    ],
                    'family' => [
                      'shopping',
                      'appointments',
                      'medication',
                      'birthdays',
                      'people',
                      'finance',
                    ],
                    _ => [
                      'affairs',
                      'projects',
                      'notes',
                      'shopping',
                      'medication',
                      'finance',
                    ],
                  };
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setStringList('home.slots', slots);
                  await prefs.setInt('home.capacity', 6);
                  if (c.mounted) c.go('/today');
                },
              ),
              const SizedBox(height: 32),
              Text(
                tr(c, 'حریم خصوصی', 'Privacy'),
                style: Theme.of(c).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                tr(
                  c,
                  'داده‌ها ابتدا روی دستگاه ذخیره می‌شوند. بکاپ با کلید بازیابی رمز می‌شود. همگام‌سازی رکوردها اطلاعات را به سروری که انتخاب می‌کنی می‌فرستد و فعلاً رمزنگاری سرتاسری ندارد. دستیار فقط متن درخواست و اطلاعاتی را که صریحاً انتخاب می‌کنی ارسال می‌کند.',
                  'Data is stored on your device first. Backups use your recovery key. Record sync sends data to your selected server and is not end-to-end encrypted. The assistant sends only your prompt and explicitly selected context.',
                ),
              ),
            ],
          ),
  );
}
