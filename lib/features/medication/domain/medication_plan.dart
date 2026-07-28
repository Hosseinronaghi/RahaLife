enum MedicationForm { tablet, capsule, syrup, drops, injection, cream, inhaler, other }

class MedicationPlan {
  const MedicationPlan({
    required this.id,
    required this.name,
    required this.form,
    required this.dosage,
    required this.time,
    this.instructions,
    this.stock,
    this.active = true,
  });

  factory MedicationPlan.fromJson(Map<String, Object?> json) => MedicationPlan(
        id: json['id']! as String,
        name: json['name']! as String,
        form: MedicationForm.values.firstWhere(
          (value) => value.name == json['form'],
          orElse: () => MedicationForm.tablet,
        ),
        dosage: json['dosage']! as String,
        time: json['time']! as String,
        instructions: json['instructions'] as String?,
        stock: (json['stock'] as num?)?.toDouble(),
        active: json['active'] as bool? ?? true,
      );

  final String id;
  final String name;
  final MedicationForm form;
  final String dosage;
  final String time;
  final String? instructions;
  final double? stock;
  final bool active;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'form': form.name,
        'dosage': dosage,
        'time': time,
        'instructions': instructions,
        'stock': stock,
        'active': active,
      };

  MedicationPlan copyWith({bool? active, double? stock}) => MedicationPlan(
        id: id,
        name: name,
        form: form,
        dosage: dosage,
        time: time,
        instructions: instructions,
        stock: stock ?? this.stock,
        active: active ?? this.active,
      );
}
