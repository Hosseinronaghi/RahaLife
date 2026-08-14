import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/locale_formatters.dart';
import '../../../core/notifications/reminder_models.dart';
import '../../../core/notifications/reminder_service.dart';
import '../../../core/widgets/reminder_editor.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/domain/home_entry.dart';
import '../../home/presentation/home_controller.dart';
import 'shopping_controller.dart';

class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lists = ref.watch(shoppingProvider);
    final locale = Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shopping)),
      body: lists.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noShoppingLists,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => showShoppingListForm(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.newShoppingList),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: lists.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final list = lists[index];
                final details = <String>[
                  '${list.checkedCount}/${list.items.length} ${l10n.items}',
                  if (list.scheduledAt != null)
                    compactDualDate(list.scheduledAt!, locale),
                  if (list.location?.isNotEmpty ?? false) list.location!,
                ];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: Icon(
                      list.allChecked
                          ? Icons.shopping_cart_checkout_rounded
                          : Icons.shopping_basket_rounded,
                    ),
                    title: Text(list.title),
                    subtitle: Text(details.join(' • ')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/shopping/${list.id}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => showShoppingListForm(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

Future<void> showShoppingListForm(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final items = TextEditingController();
  final location = TextEditingController();
  final address = TextEditingController();
  var scheduledAt = DateTime.now().add(const Duration(days: 1));
  var createAffair = true;
  var reminder = const ReminderPlan(
    enabled: true,
    kind: ReminderKind.notification,
    minutesBefore: 30,
    repeat: ReminderRepeat.none,
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        final locale = Localizations.localeOf(context);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.newShoppingList,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: title,
                    autofocus: true,
                    decoration: InputDecoration(labelText: l10n.listName),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? l10n.requiredField
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: items,
                    minLines: 5,
                    maxLines: 10,
                    decoration: InputDecoration(
                      labelText: l10n.shoppingItems,
                      hintText: l10n.oneItemPerLine,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: location,
                    decoration: InputDecoration(
                      labelText: '${l10n.storeOrLocation} (${l10n.optional})',
                      prefixIcon: const Icon(Icons.storefront_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: address,
                    minLines: 2,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: '${l10n.address} (${l10n.optional})',
                      prefixIcon: const Icon(Icons.map_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: scheduledAt,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2120),
                          );
                          if (selected != null) {
                            setState(
                              () => scheduledAt = DateTime(
                                selected.year,
                                selected.month,
                                selected.day,
                                scheduledAt.hour,
                                scheduledAt.minute,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded),
                        label: Text(compactDualDate(scheduledAt, locale)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(scheduledAt),
                          );
                          if (selected != null) {
                            setState(
                              () => scheduledAt = DateTime(
                                scheduledAt.year,
                                scheduledAt.month,
                                scheduledAt.day,
                                selected.hour,
                                selected.minute,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.schedule_rounded),
                        label: Text(localizedTime(scheduledAt, locale)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.linkShoppingToAffair),
                    subtitle: Text(l10n.linkShoppingToAffairHint),
                    value: createAffair,
                    onChanged: (value) => setState(() => createAffair = value),
                  ),
                  ReminderEditor(
                    plan: reminder,
                    allowedBeforeMinutes: const [0, 15, 30, 60, 120, 1440],
                    onChanged: (value) => setState(() => reminder = value),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final list = ref.read(shoppingProvider.notifier).addList(
                            title.text,
                            items.text.split('\n'),
                            scheduledAt: scheduledAt,
                            location: location.text,
                            address: address.text,
                            reminder: reminder,
                          );
                      if (createAffair) {
                        final affair = ref.read(homeEntriesProvider.notifier).add(
                              type: HomeEntryType.affair,
                              title: title.text,
                              details: l10n.shoppingAffairDescription,
                              dateTime: scheduledAt,
                              subtype: AffairKind.shopping.name,
                              location: location.text,
                              address: address.text,
                              linkedShoppingListId: list.id,
                              reminder: reminder,
                            );
                        ref
                            .read(shoppingProvider.notifier)
                            .linkAffair(list.id, affair.id);
                      }
                      if (reminder.enabled) {
                        await ReminderService.instance.requestPermissions();
                        await ReminderService.instance.schedule(
                          key: 'shopping:${list.id}',
                          title: list.title,
                          body: l10n.shoppingReminderBody(list.items.length),
                          eventDateTime: scheduledAt,
                          plan: reminder,
                          payload: 'shopping:${list.id}',
                        );
                      }
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  title.dispose();
  items.dispose();
  location.dispose();
  address.dispose();
}

