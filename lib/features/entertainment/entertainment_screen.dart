import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/persistence/drift_entity_repository.dart';
import '../../core/widgets/retained_popup.dart';
import '../../core/widgets/calendar_date_picker.dart';
import '../../core/localization/locale_formatters.dart';
import '../files/files_screen.dart';

class EntertainmentScreen extends StatefulWidget {
  const EntertainmentScreen({this.repository, super.key});
  final DriftEntityRepository? repository;
  @override
  State<EntertainmentScreen> createState() => _EntertainmentState();
}

class _EntertainmentState extends State<EntertainmentScreen> {
  late final repo = widget.repository ?? DriftEntityRepository();
  List<Map<String, Object?>> items = [];
  bool loading = true;
  String filter = 'all', error = '';
  static const kinds = {
    'film': ['فیلم', 'Film'],
    'series': ['سریال', 'Series'],
    'book': ['کتاب', 'Book'],
    'podcast': ['پادکست', 'Podcast'],
    'game': ['بازی', 'Game'],
    'outing': ['تفریح', 'Outing'],
  };
  static const statuses = {
    'planned': ['در برنامه', 'Planned'],
    'doing': ['در حال انجام', 'In progress'],
    'done': ['تمام‌شده', 'Finished'],
  };
  String t(String fa, String en) =>
      Localizations.localeOf(context).languageCode == 'fa' ? fa : en;
  String label(List<String>? pair) => pair == null ? '' : t(pair[0], pair[1]);
  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final rows = await repo.loadAll('entertainment');
      if (mounted) {
        setState(() {
          items = rows;
          loading = false;
          error = '';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = t('اطلاعات خوانده نشد.', 'Could not load items.');
        });
      }
    }
  }

  Future<void> edit([Map<String, Object?>? original]) async {
    final title = TextEditingController(
      text: original?['title']?.toString() ?? '',
    );
    final url = TextEditingController(text: original?['url']?.toString() ?? '');
    final progress = TextEditingController(
      text: original?['progress']?.toString() ?? '0',
    );
    final notes = TextEditingController(
      text: original?['notes']?.toString() ?? '',
    );
    var kind = original?['kind']?.toString() ?? 'film',
        status = original?['status']?.toString() ?? 'planned';
    DateTime? release = DateTime.tryParse(
          original?['releaseAt']?.toString() ?? '',
        )?.toLocal(),
        plan = DateTime.tryParse(
          original?['plannedAt']?.toString() ?? '',
        )?.toLocal();
    var remind = original?['remind'] == true, busy = false;
    String? problem;
    Future<DateTime?> select(BuildContext c, DateTime? initial) async {
      final day = await showCalendarDatePicker(
        c,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2200),
        calendar: Localizations.localeOf(c).languageCode == 'fa'
            ? 'jalali'
            : 'gregorian',
      );
      if (day == null || !c.mounted) return null;
      final time = await showTimePicker(
        context: c,
        initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
      );
      return time == null
          ? null
          : DateTime(day.year, day.month, day.day, time.hour, time.minute);
    }

    await showRetainedBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24 + MediaQuery.viewInsetsOf(c).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t('سرگرمی من', 'My entertainment'),
                style: Theme.of(c).textTheme.titleLarge,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: title,
                decoration: InputDecoration(labelText: t('عنوان', 'Title')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: kind,
                decoration: InputDecoration(labelText: t('نوع', 'Type')),
                items: [
                  for (final k in kinds.entries)
                    DropdownMenuItem(value: k.key, child: Text(label(k.value))),
                ],
                onChanged: busy ? null : (v) => set(() => kind = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: InputDecoration(labelText: t('وضعیت', 'Status')),
                items: [
                  for (final k in statuses.entries)
                    DropdownMenuItem(value: k.key, child: Text(label(k.value))),
                ],
                onChanged: busy ? null : (v) => set(() => status = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: progress,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t(
                    'پیشرفت (قسمت، صفحه یا مرحله)',
                    'Progress (episode, page or level)',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: url,
                decoration: InputDecoration(
                  labelText: t('پیوند اختیاری', 'Optional link'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: t('توضیحات', 'Notes')),
              ),
              ListTile(
                title: Text(t('زمان انتشار', 'Release time')),
                subtitle: Text(
                  release == null
                      ? t('تعیین نشده', 'Not set')
                      : compactDualDate(release!, Localizations.localeOf(c)),
                ),
                onTap: busy
                    ? null
                    : () async {
                        final d = await select(c, release);
                        if (d != null && c.mounted) set(() => release = d);
                      },
                trailing: IconButton(
                  onPressed: busy ? null : () => set(() => release = null),
                  icon: const Icon(Icons.clear),
                ),
              ),
              ListTile(
                title: Text(
                  t('زمانی که خودم می‌خواهم انجام بدهم', 'My planned time'),
                ),
                subtitle: Text(
                  plan == null
                      ? t('تعیین نشده', 'Not set')
                      : '${compactDualDate(plan!, Localizations.localeOf(c))} · ${TimeOfDay.fromDateTime(plan!).format(c)}',
                ),
                onTap: busy
                    ? null
                    : () async {
                        final d = await select(c, plan);
                        if (d != null && c.mounted) set(() => plan = d);
                      },
                trailing: IconButton(
                  onPressed: busy
                      ? null
                      : () => set(() {
                          plan = null;
                          remind = false;
                        }),
                  icon: const Icon(Icons.clear),
                ),
              ),
              SwitchListTile(
                title: Text(
                  t('یادآوری زمان شخصی', 'Remind me at my planned time'),
                ),
                value: remind,
                onChanged: plan == null || busy
                    ? null
                    : (v) => set(() => remind = v),
              ),
              if (problem != null)
                Text(
                  problem!,
                  style: TextStyle(color: Theme.of(c).colorScheme.error),
                ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        final number = int.tryParse(
                          progress.text.replaceAllMapped(RegExp('[۰-۹٠-٩]'), (
                            m,
                          ) {
                            final v = m[0]!.codeUnitAt(0);
                            return (v >= 0x6f0 ? v - 0x6f0 : v - 0x660)
                                .toString();
                          }),
                        );
                        final link = Uri.tryParse(url.text.trim());
                        if (title.text.trim().isEmpty ||
                            number == null ||
                            number < 0 ||
                            (url.text.trim().isNotEmpty &&
                                (link == null ||
                                    link.scheme != 'https' ||
                                    link.host.isEmpty ||
                                    link.userInfo.isNotEmpty))) {
                          set(
                            () => problem = t(
                              'عنوان، پیشرفت و پیوند HTTPS را بررسی کنید.',
                              'Check title, progress and HTTPS link.',
                            ),
                          );
                          return;
                        }
                        set(() => busy = true);
                        try {
                          final item = <String, Object?>{
                            ...?original,
                            'id': original?['id'] ?? const Uuid().v4(),
                            'title': title.text.trim(),
                            'kind': kind,
                            'status': status,
                            'progress': number,
                            'url': url.text.trim(),
                            'notes': notes.text.trim(),
                            'releaseAt': release?.toUtc().toIso8601String(),
                            'plannedAt': plan?.toUtc().toIso8601String(),
                            'remind': remind,
                          };
                          if (original == null) {
                            await repo.upsert('entertainment', item);
                          } else {
                            await repo.updateFromSnapshot(
                              'entertainment',
                              item,
                              original,
                            );
                          }
                          if (c.mounted) Navigator.pop(c);
                        } catch (_) {
                          if (c.mounted) {
                            set(
                              () => problem = t(
                                'ذخیره نشد؛ دوباره بررسی کنید.',
                                'Could not save. Review and retry.',
                              ),
                            );
                          }
                        } finally {
                          if (c.mounted) set(() => busy = false);
                        }
                      },
                child: Text(t('ذخیره', 'Save')),
              ),
            ],
          ),
        ),
      ),
    );
    title.dispose();
    url.dispose();
    progress.dispose();
    notes.dispose();
    await refresh();
  }

  Future<void> remove(Map<String, Object?> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t('حذف این مورد؟', 'Delete this item?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(t('لغو', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(t('حذف', 'Delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await repo.deleteFromSnapshot('entertainment', item);
      await refresh();
    } catch (_) {
      if (mounted) setState(() => error = t('حذف نشد.', 'Could not delete.'));
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(t('سرگرمی', 'Entertainment'))),
    floatingActionButton: FloatingActionButton(
      onPressed: () => edit(),
      child: const Icon(Icons.add),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(t('همه', 'All')),
                    selected: filter == 'all',
                    onSelected: (_) => setState(() => filter = 'all'),
                  ),
                  for (final k in kinds.entries)
                    ChoiceChip(
                      label: Text(label(k.value)),
                      selected: filter == k.key,
                      onSelected: (_) => setState(() => filter = k.key),
                    ),
                ],
              ),
              if (error.isNotEmpty)
                TextButton(onPressed: refresh, child: Text(error)),
              for (final item in items.where(
                (e) => filter == 'all' || e['kind'] == filter,
              ))
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(item['title'].toString()),
                        subtitle: Text(
                          '${label(kinds[item['kind']])} · ${label(statuses[item['status']])} · ${item['progress']}',
                        ),
                        onTap: () => edit(item),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.of(c).push(
                              MaterialPageRoute<void>(
                                builder: (_) => FilesScreen(
                                  entityType: 'entertainment',
                                  entityId: item['id'].toString(),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.attach_file),
                            label: Text(t('فایل و صدا', 'Files and voice')),
                          ),
                          if (item['url']?.toString().isNotEmpty ?? false)
                            TextButton.icon(
                              onPressed: () async {
                                final u = Uri.tryParse(item['url'].toString());
                                if (u == null ||
                                    u.scheme != 'https' ||
                                    u.host.isEmpty) {
                                  return;
                                }
                                try {
                                  await launchUrl(
                                    u,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (_) {
                                  if (mounted) {
                                    setState(
                                      () => error = t(
                                        'پیوند باز نشد.',
                                        'Could not open link.',
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: Text(t('بازکردن پیوند', 'Open link')),
                            ),
                          IconButton(
                            onPressed: () => remove(item),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    t(
                      'فیلم، سریال، کتاب یا برنامه تفریحی خود را اضافه کنید.',
                      'Add a film, series, book or leisure plan.',
                    ),
                  ),
                ),
            ],
          ),
  );
}
