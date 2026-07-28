class Person {
  const Person({
    required this.id,
    required this.name,
    this.relationship,
    this.phone,
    this.email,
    this.birthDate,
    this.notes,
  });

  factory Person.fromJson(Map<String, Object?> json) => Person(
        id: json['id']! as String,
        name: json['name']! as String,
        relationship: json['relationship'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        birthDate: json['birthDate'] == null
            ? null
            : DateTime.parse(json['birthDate']! as String),
        notes: json['notes'] as String?,
      );

  final String id;
  final String name;
  final String? relationship;
  final String? phone;
  final String? email;
  final DateTime? birthDate;
  final String? notes;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'phone': phone,
        'email': email,
        'birthDate': birthDate?.toIso8601String(),
        'notes': notes,
      };
}
