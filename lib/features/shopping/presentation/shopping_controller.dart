import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/notifications/reminder_models.dart';
import '../../../core/notifications/reminder_service.dart';
import '../domain/shopping_list.dart';

class ShoppingNotifier extends StateNotifier<List<ShoppingListData>> {
  ShoppingNotifier({this.persistenceEnabled = true}) : super(const []) {
    if (persistenceEnabled) unawaited(_load());
  }

  static const _key = 'shopping.lists.v2';
  static const _legacyKey = 'shopping.lists.v1';
  static const _uuid = Uuid();
  final bool persistenceEnabled;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? prefs.getString(_legacyKey);
    if (raw == null || raw.isEmpty) return;
    try {
      state = (jsonDecode(raw) as List<dynamic>)
          .map(
            (item) => ShoppingListData.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList();
      await _persist();
    } catch (_) {}
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((item) => item.toJson()).toList()),
    );
  }

  ShoppingListData addList(
    String title,
    List<String> itemTitles, {
    DateTime? scheduledAt,
    String? location,
    String? address,
    ReminderPlan reminder = const ReminderPlan(),
  }) {
    final items = itemTitles
        .where((item) => item.trim().isNotEmpty)
        .map((item) => ShoppingItemData(id: _uuid.v4(), title: item.trim()))
        .toList();
    final list = ShoppingListData(
      id: _uuid.v4(),
      title: title.trim(),
      items: items,
      scheduledAt: scheduledAt,
      location: location?.trim().isEmpty ?? true ? null : location!.trim(),
      address: address?.trim().isEmpty ?? true ? null : address!.trim(),
      reminder: reminder,
    );
    state = [...state, list];
    unawaited(_persist());
    return list;
  }

  void linkAffair(String listId, String affairId) {
    state = [
      for (final list in state)
        if (list.id == listId)
          list.copyWith(linkedAffairId: affairId)
        else
          list,
    ];
    unawaited(_persist());
  }

  void addItems(String listId, List<String> itemTitles) {
    state = [
      for (final list in state)
        if (list.id == listId)
          list.copyWith(
            items: [
              ...list.items,
              ...itemTitles
                  .where((item) => item.trim().isNotEmpty)
                  .map(
                    (item) => ShoppingItemData(
                      id: _uuid.v4(),
                      title: item.trim(),
                    ),
                  ),
            ],
          )
        else
          list,
    ];
    unawaited(_persist());
  }

  void toggleItem(String listId, String itemId) {
    state = [
      for (final list in state)
        if (list.id == listId)
          list.copyWith(
            items: [
              for (final item in list.items)
                if (item.id == itemId)
                  item.copyWith(checked: !item.checked)
                else
                  item,
            ],
            completed: list.items.isNotEmpty &&
                list.items.every(
                  (item) => item.id == itemId ? !item.checked : item.checked,
                ),
          )
        else
          list,
    ];
    unawaited(_persist());
  }

  void deleteList(String id) {
    state = state.where((list) => list.id != id).toList();
    unawaited(ReminderService.instance.cancel('shopping:$id'));
    unawaited(_persist());
  }
}

final shoppingProvider =
    StateNotifierProvider<ShoppingNotifier, List<ShoppingListData>>(
  (ref) => ShoppingNotifier(),
);
