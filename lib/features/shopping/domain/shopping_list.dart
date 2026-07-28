class ShoppingItemData {
  const ShoppingItemData({
    required this.id,
    required this.title,
    this.quantity,
    this.unit,
    this.checked = false,
  });

  factory ShoppingItemData.fromJson(Map<String, Object?> json) => ShoppingItemData(
        id: json['id']! as String,
        title: json['title']! as String,
        quantity: (json['quantity'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        checked: json['checked'] as bool? ?? false,
      );

  final String id;
  final String title;
  final double? quantity;
  final String? unit;
  final bool checked;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'quantity': quantity,
        'unit': unit,
        'checked': checked,
      };

  ShoppingItemData copyWith({bool? checked}) => ShoppingItemData(
        id: id,
        title: title,
        quantity: quantity,
        unit: unit,
        checked: checked ?? this.checked,
      );
}

class ShoppingListData {
  const ShoppingListData({required this.id, required this.title, required this.items});

  factory ShoppingListData.fromJson(Map<String, Object?> json) => ShoppingListData(
        id: json['id']! as String,
        title: json['title']! as String,
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((item) => ShoppingItemData.fromJson(Map<String, Object?>.from(item as Map)))
            .toList(),
      );

  final String id;
  final String title;
  final List<ShoppingItemData> items;

  int get checkedCount => items.where((item) => item.checked).length;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'items': items.map((item) => item.toJson()).toList(),
      };

  ShoppingListData copyWith({List<ShoppingItemData>? items}) => ShoppingListData(
        id: id,
        title: title,
        items: items ?? this.items,
      );
}
