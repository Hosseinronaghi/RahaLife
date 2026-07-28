import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'shopping_controller.dart';

class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lists = ref.watch(shoppingProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shopping)),
      body: lists.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 72),
                  const SizedBox(height: 16),
                  Text(l10n.noShoppingLists, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: () => showShoppingListForm(context, ref), icon: const Icon(Icons.add_rounded), label: Text(l10n.newShoppingList)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: lists.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final list = lists[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: const Icon(Icons.shopping_basket_rounded),
                    title: Text(list.title),
                    subtitle: Text('${list.checkedCount}/${list.items.length} ${l10n.items}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/shopping/${list.id}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.small(onPressed: () => showShoppingListForm(context, ref), child: const Icon(Icons.add_rounded)),
    );
  }
}

Future<void> showShoppingListForm(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final items = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.newShoppingList, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(controller: title, autofocus: true, decoration: InputDecoration(labelText: l10n.listName), validator: (v) => v == null || v.trim().isEmpty ? l10n.requiredField : null),
              const SizedBox(height: 12),
              TextFormField(controller: items, minLines: 5, maxLines: 10, decoration: InputDecoration(labelText: l10n.shoppingItems, hintText: l10n.oneItemPerLine)),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  ref.read(shoppingProvider.notifier).addList(title.text, items.text.split('\n'));
                  Navigator.pop(sheetContext);
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  title.dispose(); items.dispose();
}
