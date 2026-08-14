import 'medication_plan.dart';

class MedicationCatalogItem {
  const MedicationCatalogItem({
    required this.genericName,
    required this.groupEn,
    required this.groupFa,
    required this.commonUseEn,
    required this.commonUseFa,
    this.defaultForm = MedicationForm.tablet,
    this.brandExamples = const [],
  });

  final String genericName;
  final String groupEn;
  final String groupFa;
  final String commonUseEn;
  final String commonUseFa;
  final MedicationForm defaultForm;
  final List<String> brandExamples;

  String groupFor(String languageCode) => languageCode == 'fa' ? groupFa : groupEn;
  String commonUseFor(String languageCode) =>
      languageCode == 'fa' ? commonUseFa : commonUseEn;
}

/// Starter catalog for record entry only. It is not a prescribing engine.
/// A remote authoritative medication terminology provider can extend this list
/// later without changing the user's medication records.
const medicationStarterCatalog = <MedicationCatalogItem>[
  MedicationCatalogItem(genericName: 'Acetaminophen / Paracetamol', groupEn: 'Pain & fever', groupFa: 'درد و تب', commonUseEn: 'Pain or fever', commonUseFa: 'درد یا تب'),
  MedicationCatalogItem(genericName: 'Ibuprofen', groupEn: 'Pain & inflammation', groupFa: 'درد و التهاب', commonUseEn: 'Pain or inflammation', commonUseFa: 'درد یا التهاب'),
  MedicationCatalogItem(genericName: 'Naproxen', groupEn: 'Pain & inflammation', groupFa: 'درد و التهاب', commonUseEn: 'Pain or inflammation', commonUseFa: 'درد یا التهاب'),
  MedicationCatalogItem(genericName: 'Cetirizine', groupEn: 'Allergy', groupFa: 'حساسیت', commonUseEn: 'Allergy symptoms', commonUseFa: 'علائم حساسیت'),
  MedicationCatalogItem(genericName: 'Loratadine', groupEn: 'Allergy', groupFa: 'حساسیت', commonUseEn: 'Allergy symptoms', commonUseFa: 'علائم حساسیت'),
  MedicationCatalogItem(genericName: 'Omeprazole', groupEn: 'Gastrointestinal', groupFa: 'گوارش', commonUseEn: 'Acid-related symptoms', commonUseFa: 'مشکلات مرتبط با اسید معده', defaultForm: MedicationForm.capsule),
  MedicationCatalogItem(genericName: 'Pantoprazole', groupEn: 'Gastrointestinal', groupFa: 'گوارش', commonUseEn: 'Acid-related symptoms', commonUseFa: 'مشکلات مرتبط با اسید معده'),
  MedicationCatalogItem(genericName: 'Famotidine', groupEn: 'Gastrointestinal', groupFa: 'گوارش', commonUseEn: 'Acid-related symptoms', commonUseFa: 'مشکلات مرتبط با اسید معده'),
  MedicationCatalogItem(genericName: 'Metformin', groupEn: 'Diabetes', groupFa: 'دیابت', commonUseEn: 'Blood glucose management', commonUseFa: 'کنترل قند خون'),
  MedicationCatalogItem(genericName: 'Losartan', groupEn: 'Cardiovascular', groupFa: 'قلب و عروق', commonUseEn: 'Blood pressure management', commonUseFa: 'کنترل فشار خون'),
  MedicationCatalogItem(genericName: 'Amlodipine', groupEn: 'Cardiovascular', groupFa: 'قلب و عروق', commonUseEn: 'Blood pressure management', commonUseFa: 'کنترل فشار خون'),
  MedicationCatalogItem(genericName: 'Atorvastatin', groupEn: 'Cardiovascular', groupFa: 'قلب و عروق', commonUseEn: 'Cholesterol management', commonUseFa: 'کنترل چربی خون'),
  MedicationCatalogItem(genericName: 'Levothyroxine', groupEn: 'Endocrine', groupFa: 'غدد', commonUseEn: 'Thyroid hormone replacement', commonUseFa: 'جایگزینی هورمون تیروئید'),
  MedicationCatalogItem(genericName: 'Albuterol / Salbutamol', groupEn: 'Respiratory', groupFa: 'تنفسی', commonUseEn: 'Airway symptoms', commonUseFa: 'علائم راه‌های هوایی', defaultForm: MedicationForm.inhaler),
  MedicationCatalogItem(genericName: 'Budesonide', groupEn: 'Respiratory', groupFa: 'تنفسی', commonUseEn: 'Airway inflammation', commonUseFa: 'التهاب راه‌های هوایی', defaultForm: MedicationForm.inhaler),
  MedicationCatalogItem(genericName: 'Amoxicillin', groupEn: 'Antibiotic', groupFa: 'آنتی‌بیوتیک', commonUseEn: 'Bacterial infections', commonUseFa: 'عفونت‌های باکتریایی', defaultForm: MedicationForm.capsule),
  MedicationCatalogItem(genericName: 'Azithromycin', groupEn: 'Antibiotic', groupFa: 'آنتی‌بیوتیک', commonUseEn: 'Bacterial infections', commonUseFa: 'عفونت‌های باکتریایی'),
  MedicationCatalogItem(genericName: 'Sertraline', groupEn: 'Mental health', groupFa: 'سلامت روان', commonUseEn: 'Prescribed mental health treatment', commonUseFa: 'درمان تجویزشده سلامت روان'),
  MedicationCatalogItem(genericName: 'Escitalopram', groupEn: 'Mental health', groupFa: 'سلامت روان', commonUseEn: 'Prescribed mental health treatment', commonUseFa: 'درمان تجویزشده سلامت روان'),
  MedicationCatalogItem(genericName: 'Gabapentin', groupEn: 'Neurology / pain', groupFa: 'عصب و درد', commonUseEn: 'Prescribed neurologic or pain treatment', commonUseFa: 'درمان تجویزشده عصبی یا درد', defaultForm: MedicationForm.capsule),
  MedicationCatalogItem(genericName: 'Vitamin D3', groupEn: 'Vitamins', groupFa: 'ویتامین', commonUseEn: 'Vitamin D supplementation', commonUseFa: 'مکمل ویتامین D'),
  MedicationCatalogItem(genericName: 'Ferrous sulfate', groupEn: 'Minerals', groupFa: 'مواد معدنی', commonUseEn: 'Iron supplementation', commonUseFa: 'مکمل آهن'),
  MedicationCatalogItem(genericName: 'Hydrocortisone', groupEn: 'Dermatology', groupFa: 'پوست', commonUseEn: 'Skin inflammation', commonUseFa: 'التهاب پوستی', defaultForm: MedicationForm.cream),
  MedicationCatalogItem(genericName: 'Insulin', groupEn: 'Diabetes', groupFa: 'دیابت', commonUseEn: 'Insulin therapy', commonUseFa: 'درمان با انسولین', defaultForm: MedicationForm.injection),
];
