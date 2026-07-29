import '../../../core/notifications/reminder_models.dart';

class ShoppingItemData {
  const ShoppingItemData({
    required this.id,
    required this.title,
    this.quantity,
    this.unit,
    this.checked = false,
  });

  factory ShoppingItemData.fromJson(Map<String, Object?> json) =>
      ShoppingItemData(
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
  const ShoppingListData({
    required this.id,
    required this.title,
    required this.items,
    this.scheduledAt,
    this.location,
    this.address,
    this.linkedAffairId,
    this.reminder = const ReminderPlan(),
    this.completed = false,
  });

  factory ShoppingListData.fromJson(Map<String, Object?> json) =>
      ShoppingListData(
        id: json['id']! as String,
        title: json['title']! as String,
        items: (json['items'] as List<dynamic>? ?? const [])
            .map(
              (item) => ShoppingItemData.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList(),
        scheduledAt: json['scheduledAt'] == null
            ? null
            : DateTime.parse(json['scheduledAt']! as String),
        location: json['location'] as String?,
        address: json['address'] as String?,
        linkedAffairId: json['linkedAffairId'] as String?,
        reminder: ReminderPlan.fromJson(
          json['reminder'] is Map
              ? Map<String, Object?>.from(json['reminder']! as Map)
              : null,
        ),
        completed: json['completed'] as bool? ?? false,
      );

  final String id;
  final String title;
  final List<ShoppingItemData> items;
  final DateTime? scheduledAt;
  final String? location;
  final String? address;
  final String? linkedAffairId;
  final ReminderPlan reminder;
  final bool completed;

  int get checkedCount => items.where((item) => item.checked).length;
  bool get allChecked => items.isNotEmpty && checkedCount == items.length;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'items': items.map((item) => item.toJson()).toList(),
        'scheduledAt': scheduledAt?.toIso8601String(),
        'location': location,
        'address': address,
        'linkedAffairId': linkedAffairId,
        'reminder': reminder.toJson(),
        'completed': completed,
      };

  ShoppingListData copyWith({
    List<ShoppingItemData>? items,
    DateTime? scheduledAt,
    String? location,
    String? address,
    String? linkedAffairId,
    ReminderPlan? reminder,
    bool? completed,
  }) =>
      ShoppingListData(
        id: id,
        title: title,
        items: items ?? this.items,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        location: location ?? this.location,
        address: address ?? this.address,
        linkedAffairId: linkedAffairId ?? this.linkedAffairId,
        reminder: reminder ?? this.reminder,
        completed: completed ?? this.completed,
      );
}
