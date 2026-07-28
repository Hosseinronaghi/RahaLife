import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/shopping_list.dart';
import 'shopping_controller.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({required this.listId, super.key});
  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lists = ref.watch(shoppingProvider);
    final matches = lists.where((item) => item.id == listId);
    if (matches.isEmpty) return Scaffold(appBar: AppBar(), body: Center(child: Text(l10n.noSearchResults)));
    final list = matches.first;
    final sorted = [...list.items]..sort((a, b) => a.checked == b.checked ? 0 : (a.checked ? 1 : -1));
    return Scaffold(
      appBar: AppBar(
        title: Text(list.title),
        actions: [
          IconButton(
            tooltip: l10n.share,
            onPressed: () async {
              final text = _shareText(list.title, sorted);
              final box = context.findRenderObject() as RenderBox?;
              final origin = box == null
                  ? const Rect.fromLTWH(0, 0, 1, 1)
                  : box.localToGlobal(Offset.zero) & box.size;
              try {
                await SharePlus.instance.share(
                  ShareParams(
                    text: text,
                    subject: list.title,
                    sharePositionOrigin: origin,
                  ),
                );
              } catch (_) {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copiedForSharing)));
              }
            },
            icon: const Icon(Icons.ios_share_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                ref.read(shoppingProvider.notifier).deleteList(list.id);
                Navigator.pop(context);
              }
            },
            itemBuilder: (_) => [PopupMenuItem(value: 'delete', child: Text(l10n.delete))],
          ),
        ],
      ),
      body: sorted.isEmpty
          ? Center(child: Text(l10n.noShoppingItems))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = sorted[index];
                return Card(
                  child: CheckboxListTile(
                    value: item.checked,
                    onChanged: (_) => ref.read(shoppingProvider.notifier).toggleItem(list.id, item.id),
                    title: Text(item.title, style: TextStyle(decoration: item.checked ? TextDecoration.lineThrough : null)),
                    secondary: Icon(item.checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _addItems(context, ref, list.id),
        child: const Icon(Icons.playlist_add_rounded),
      ),
    );
  }
}

String _shareText(String title, List<ShoppingItemData> items) {
  final buffer = StringBuffer('$title\n');
  for (final item in items) {
    buffer.writeln('${item.checked ? '☑' : '☐'} ${item.title}');
  }
  return buffer.toString();
}

Future<void> _addItems(BuildContext context, WidgetRef ref, String listId) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.addShoppingItems, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: controller, autofocus: true, minLines: 4, maxLines: 8, decoration: InputDecoration(hintText: l10n.oneItemPerLine)),
          const SizedBox(height: 16),
          FilledButton(onPressed: () { ref.read(shoppingProvider.notifier).addItems(listId, controller.text.split('\n')); Navigator.pop(sheetContext); }, child: Text(l10n.add)),
        ],
      ),
    ),
  );
  controller.dispose();
}
