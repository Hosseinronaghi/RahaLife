import '../../../core/persistence/write_status.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/notifications/reminder_models.dart';
import '../../../core/notifications/reminder_service.dart';
import '../data/shopping_drift_repository.dart';
import '../domain/shopping_list.dart';

class ShoppingNotifier extends StateNotifier<List<ShoppingListData>> {
  ShoppingNotifier({
    this.persistenceEnabled = true,
    ShoppingDriftRepository? repository,
  }) : _repository = repository ?? ShoppingDriftRepository(),
       super(const []) {
    if (persistenceEnabled) {
      _ready = WriteStatus.load(_load);
    }
  }

  static const _uuid = Uuid();
  Future<void> _ready = Future<void>.value();
  final bool persistenceEnabled;
  final ShoppingDriftRepository _repository;

  Future<void> _load() async {
    try {
      state = await _repository.load();
    } catch (error) {
      WriteStatus.report(error);
    }
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    await _ready;
    await _repository.saveAll(state);
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
    WriteStatus.track(_persist());
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
    WriteStatus.track(_persist());
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
                    (item) =>
                        ShoppingItemData(id: _uuid.v4(), title: item.trim()),
                  ),
            ],
          )
        else
          list,
    ];
    WriteStatus.track(_persist());
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
            completed:
                list.items.isNotEmpty &&
                list.items.every(
                  (item) => item.id == itemId ? !item.checked : item.checked,
                ),
          )
        else
          list,
    ];
    WriteStatus.track(_persist());
  }

  void deleteList(String id) {
    state = state.where((list) => list.id != id).toList();
    unawaited(ReminderService.instance.cancel('shopping:$id'));
    WriteStatus.track(_persist());
  }
}

final shoppingProvider =
    StateNotifierProvider<ShoppingNotifier, List<ShoppingListData>>(
      (ref) => ShoppingNotifier(),
    );
