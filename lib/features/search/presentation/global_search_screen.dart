import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../features/home/domain/home_entry.dart';
import '../../../features/home/presentation/entry_details_sheet.dart';
import '../../../features/home/presentation/home_controller.dart';
import '../../../features/home/presentation/home_entry_ui.dart';
import '../../../l10n/generated/app_localizations.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _controller = TextEditingController();
  HomeEntryType? _filter;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _controller.text;
    var results = ref.watch(homeEntriesProvider).where((item) {
      final normalized = query.trim().toLowerCase();
      final matchesQuery = normalized.isNotEmpty &&
          (item.title.toLowerCase().contains(normalized) ||
              (item.details?.toLowerCase().contains(normalized) ?? false));
      return matchesQuery && (_filter == null || item.type == _filter);
    }).toList();
    results.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.globalSearch)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.searchEverything,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: Text(l10n.all),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                for (final type in homeSectionOrder) ...[
                  ChoiceChip(
                    avatar: Icon(homeEntryTypeIcon(type), size: 18),
                    label: Text(homeEntryTypeLabel(l10n, type)),
                    selected: _filter == type,
                    onSelected: (_) => setState(() => _filter = type),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: query.trim().isEmpty
                ? _SearchMessage(
                    icon: Icons.manage_search_rounded,
                    message: l10n.searchHint,
                  )
                : results.isEmpty
                    ? _SearchMessage(
                        icon: Icons.search_off_rounded,
                        message: l10n.noSearchResults,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final entry = results[index];
                          final color = homeEntryTypeColor(
                            entry.type,
                            Theme.of(context).colorScheme,
                          );
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.12),
                                foregroundColor: color,
                                child: Icon(homeEntryTypeIcon(entry.type)),
                              ),
                              title: Text(entry.title),
                              subtitle: Text(
                                '${homeEntryTypeLabel(l10n, entry.type)} · ${compactDualDate(entry.dateTime, Localizations.localeOf(context))}',
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => showEntryDetails(context, entry),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
}
