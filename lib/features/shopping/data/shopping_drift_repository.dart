import '../../../core/persistence/drift_entity_repository.dart';
import '../domain/shopping_list.dart';

class ShoppingDriftRepository {
  ShoppingDriftRepository({DriftEntityRepository? entities})
    : _entities = entities ?? DriftEntityRepository();

  static const listEntityType = 'shopping_list';
  static const itemEntityType = 'shopping_item';

  final DriftEntityRepository _entities;

  Future<List<ShoppingListData>> load() async {
    final listPayloads = await _entities.loadAll(listEntityType);
    final itemPayloads = await _entities.loadAll(itemEntityType);
    final itemsByList = <String, List<ShoppingItemData>>{};
    for (final payload in itemPayloads) {
      final listId = payload['listId']?.toString();
      if (listId == null) continue;
      final itemJson = Map<String, Object?>.from(payload)..remove('listId');
      itemsByList
          .putIfAbsent(listId, () => [])
          .add(ShoppingItemData.fromJson(itemJson));
    }
    return listPayloads
        .map((payload) {
          final data = Map<String, Object?>.from(payload);
          final id = data['id']!.toString();
          data['items'] = (itemsByList[id] ?? const <ShoppingItemData>[])
              .map((item) => item.toJson())
              .toList();
          return ShoppingListData.fromJson(data);
        })
        .toList(growable: false);
  }

  Future<void> saveAll(List<ShoppingListData> lists) async {
    final parentPayloads = <Map<String, Object?>>[];
    final itemPayloads = <Map<String, Object?>>[];
    for (final list in lists) {
      final parent = Map<String, Object?>.from(list.toJson())..remove('items');
      parentPayloads.add(parent);
      for (final item in list.items) {
        itemPayloads.add(<String, Object?>{
          ...item.toJson(),
          'listId': list.id,
        });
      }
    }
    await _entities.db.transaction(() async {
      await _entities.replaceAll(listEntityType, parentPayloads);
      await _entities.replaceAll(itemEntityType, itemPayloads);
    });
  }
}
