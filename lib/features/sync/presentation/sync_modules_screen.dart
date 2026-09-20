import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sync/sync_scope.dart';
import '../../../core/sync/providers/backup_target.dart';
import '../../workspace/record_editor.dart';
import 'sync_controller.dart';

class SyncModulesScreen extends ConsumerWidget {
  const SyncModulesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref
        .watch(syncSettingsProvider)
        .connections
        .where(
          (e) =>
              e.kind == SyncProviderKind.rahaServer ||
              e.kind == SyncProviderKind.customHttp,
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(context, 'انتخاب بخش‌های همگام‌سازی', 'Choose sync modules'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            tr(
              context,
              'تغییر انتخاب، دادهٔ قبلاً ارسال‌شده را از سرور حذف نمی‌کند. بکاپ کامل مستقل از این انتخاب است.',
              'Changing selection does not delete data already sent to the server. Full backups are separate.',
            ),
          ),
          if (profiles.isEmpty)
            Text(
              tr(
                context,
                'ابتدا اتصال سرور را اضافه کنید.',
                'Add a server connection first.',
              ),
            ),
          for (final profile in profiles)
            Card(
              child: ListTile(
                title: Text(profile.name),
                subtitle: Text(
                  profile.config['modules'] == null
                      ? tr(
                          context,
                          'همهٔ بخش‌ها؛ تنظیم قبلی',
                          'All modules; previous setting',
                        )
                      : tr(context, 'انتخاب سفارشی', 'Custom selection'),
                ),
                trailing: const Icon(Icons.tune),
                onTap: () => _edit(context, ref, profile),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    SyncConnectionProfile profile,
  ) async {
    final selected =
        profile.config['modules']
            ?.split(',')
            .where((e) => e.isNotEmpty)
            .toSet() ??
        syncModuleTypes.keys.toSet();
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(profile.name),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final module in syncModuleTypes.keys)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: selected.contains(module),
                      title: Text(
                        tr(
                          c,
                          const {
                            'notes': 'یادداشت‌ها',
                            'tasks': 'کارها، رویدادها و تولدهای دستی',
                            'shopping': 'خرید',
                            'projects': 'پروژه‌ها',
                            'people': 'افراد و تولدهای مرتبط',
                            'finance': 'امور مالی',
                            'health': 'چرخه و دارو',
                            'bookmarks': 'نشانک‌ها',
                            'files': 'فایل‌ها و صداها',
                            'entertainment': 'سرگرمی',
                          }[module]!,
                          module,
                        ),
                      ),
                      onChanged: (v) => set(() {
                        if (v == true) {
                          selected.add(module);
                        } else {
                          selected.remove(module);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(tr(c, 'لغو', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(tr(c, 'ذخیره', 'Save')),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      await ref
          .read(syncSettingsProvider.notifier)
          .updateConnection(
            profile: profile.copyWith(
              config: {
                ...profile.config,
                'modules': (selected.toList()..sort()).join(','),
              },
            ),
          );
    }
  }
}
