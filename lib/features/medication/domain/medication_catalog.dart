import 'medication_plan.dart';

class MedicationCatalogItem {
  const MedicationCatalogItem({
    required this.genericName,
    required this.groupEn,
    required this.groupFa,
    required this.commonUseEn,
    required this.commonUseFa,
    this.nameFa,
    this.safetyFa,
    this.safetyEn,
    this.sourceUrl,
    this.checkedOn,
    this.defaultForm = MedicationForm.tablet,
    this.brandExamples = const [],
  });

  final String genericName;
  final String? nameFa, safetyFa, safetyEn, sourceUrl, checkedOn;
  String nameFor(String lang) =>
      lang == 'fa' ? (nameFa ?? genericName) : genericName;
  String? safetyFor(String lang) => lang == 'fa' ? safetyFa : safetyEn;
  final String groupEn;
  final String groupFa;
  final String commonUseEn;
  final String commonUseFa;
  final MedicationForm defaultForm;
  final List<String> brandExamples;

  String groupFor(String languageCode) =>
      languageCode == 'fa' ? groupFa : groupEn;
  String commonUseFor(String languageCode) =>
      languageCode == 'fa' ? commonUseFa : commonUseEn;
}

/// Starter catalog for record entry only. It is not a prescribing engine.
/// A remote authoritative medication terminology provider can extend this list
/// later without changing the user's medication records.
const medicationStarterCatalog = <MedicationCatalogItem>[
  MedicationCatalogItem(
    genericName: 'Acetaminophen / Paracetamol',
    nameFa: 'استامینوفن / پاراستامول',
    groupEn: 'Pain & fever',
    groupFa: 'درد و تب',
    commonUseEn: 'Pain or fever',
    commonUseFa: 'درد یا تب',
  ),
  MedicationCatalogItem(
    genericName: 'Ibuprofen',
    nameFa: 'ایبوپروفن',
    groupEn: 'Pain & inflammation',
    groupFa: 'درد و التهاب',
    commonUseEn: 'Pain or inflammation',
    commonUseFa: 'درد یا التهاب',
  ),
  MedicationCatalogItem(
    genericName: 'Naproxen',
    nameFa: 'ناپروکسن',
    groupEn: 'Pain & inflammation',
    groupFa: 'درد و التهاب',
    commonUseEn: 'Pain or inflammation',
    commonUseFa: 'درد یا التهاب',
  ),
  MedicationCatalogItem(
    genericName: 'Cetirizine',
    nameFa: 'ستیریزین',
    groupEn: 'Allergy',
    groupFa: 'حساسیت',
    commonUseEn: 'Allergy symptoms',
    commonUseFa: 'علائم حساسیت',
  ),
  MedicationCatalogItem(
    genericName: 'Loratadine',
    nameFa: 'لوراتادین',
    groupEn: 'Allergy',
    groupFa: 'حساسیت',
    commonUseEn: 'Allergy symptoms',
    commonUseFa: 'علائم حساسیت',
  ),
  MedicationCatalogItem(
    genericName: 'Omeprazole',
    nameFa: 'امپرازول',
    groupEn: 'Gastrointestinal',
    groupFa: 'گوارش',
    commonUseEn: 'Acid-related symptoms',
    commonUseFa: 'مشکلات مرتبط با اسید معده',
    defaultForm: MedicationForm.capsule,
  ),
  MedicationCatalogItem(
    genericName: 'Pantoprazole',
    nameFa: 'پانتوپرازول',
    groupEn: 'Gastrointestinal',
    groupFa: 'گوارش',
    commonUseEn: 'Acid-related symptoms',
    commonUseFa: 'مشکلات مرتبط با اسید معده',
  ),
  MedicationCatalogItem(
    genericName: 'Famotidine',
    nameFa: 'فاموتیدین',
    groupEn: 'Gastrointestinal',
    groupFa: 'گوارش',
    commonUseEn: 'Acid-related symptoms',
    commonUseFa: 'مشکلات مرتبط با اسید معده',
  ),
  MedicationCatalogItem(
    genericName: 'Metformin',
    nameFa: 'متفورمین',
    groupEn: 'Diabetes',
    groupFa: 'دیابت',
    commonUseEn: 'Blood glucose management',
    commonUseFa: 'کنترل قند خون',
  ),
  MedicationCatalogItem(
    genericName: 'Losartan',
    nameFa: 'لوزارتان',
    groupEn: 'Cardiovascular',
    groupFa: 'قلب و عروق',
    commonUseEn: 'Blood pressure management',
    commonUseFa: 'کنترل فشار خون',
  ),
  MedicationCatalogItem(
    genericName: 'Amlodipine',
    nameFa: 'آملودیپین',
    groupEn: 'Cardiovascular',
    groupFa: 'قلب و عروق',
    commonUseEn: 'Blood pressure management',
    commonUseFa: 'کنترل فشار خون',
  ),
  MedicationCatalogItem(
    genericName: 'Atorvastatin',
    nameFa: 'آتورواستاتین',
    groupEn: 'Cardiovascular',
    groupFa: 'قلب و عروق',
    commonUseEn: 'Cholesterol management',
    commonUseFa: 'کنترل چربی خون',
  ),
  MedicationCatalogItem(
    genericName: 'Levothyroxine',
    nameFa: 'لووتیروکسین',
    groupEn: 'Endocrine',
    groupFa: 'غدد',
    commonUseEn: 'Thyroid hormone replacement',
    commonUseFa: 'جایگزینی هورمون تیروئید',
  ),
  MedicationCatalogItem(
    genericName: 'Albuterol / Salbutamol',
    safetyFa:
        'شکل استنشاقی ممکن است لرزش، سردرد یا تندشدن ضربان ایجاد کند. تنگی نفس جدید یا بدترشونده و درد قفسه سینه نیازمند رسیدگی فوری‌اند. ضربان نامنظم پایدار یا ضعف عضلانی را سریع با پزشک مطرح کنید.',
    safetyEn:
        'Inhaled salbutamol may cause tremor, headache or a fast heartbeat. New or worsening breathlessness or chest pain needs emergency care. Seek prompt advice for persistent irregular heartbeat or muscle weakness.',
    sourceUrl:
        'https://www.nhs.uk/medicines/salbutamol-inhaler/side-effects-of-salbutamol-inhalers/',
    checkedOn: '2026-09-20',
    nameFa: 'آلبوترول / سالبوتامول',
    groupEn: 'Respiratory',
    groupFa: 'تنفسی',
    commonUseEn: 'Airway symptoms',
    commonUseFa: 'علائم راه‌های هوایی',
    defaultForm: MedicationForm.inhaler,
  ),
  MedicationCatalogItem(
    genericName: 'Budesonide',
    nameFa: 'بودزوناید',
    groupEn: 'Respiratory',
    groupFa: 'تنفسی',
    commonUseEn: 'Airway inflammation',
    commonUseFa: 'التهاب راه‌های هوایی',
    defaultForm: MedicationForm.inhaler,
  ),
  MedicationCatalogItem(
    genericName: 'Amoxicillin',
    nameFa: 'آموکسی‌سیلین',
    groupEn: 'Antibiotic',
    groupFa: 'آنتی‌بیوتیک',
    commonUseEn: 'Bacterial infections',
    commonUseFa: 'عفونت‌های باکتریایی',
    defaultForm: MedicationForm.capsule,
  ),
  MedicationCatalogItem(
    genericName: 'Azithromycin',
    nameFa: 'آزیترومایسین',
    groupEn: 'Antibiotic',
    groupFa: 'آنتی‌بیوتیک',
    commonUseEn: 'Bacterial infections',
    commonUseFa: 'عفونت‌های باکتریایی',
  ),
  MedicationCatalogItem(
    genericName: 'Sertraline',
    nameFa: 'سرترالین',
    groupEn: 'Mental health',
    groupFa: 'سلامت روان',
    commonUseEn: 'Prescribed mental health treatment',
    commonUseFa: 'درمان تجویزشده سلامت روان',
  ),
  MedicationCatalogItem(
    genericName: 'Escitalopram',
    nameFa: 'اس‌سیتالوپرام',
    groupEn: 'Mental health',
    groupFa: 'سلامت روان',
    commonUseEn: 'Prescribed mental health treatment',
    commonUseFa: 'درمان تجویزشده سلامت روان',
  ),
  MedicationCatalogItem(
    genericName: 'Gabapentin',
    nameFa: 'گاباپنتین',
    groupEn: 'Neurology / pain',
    groupFa: 'عصب و درد',
    commonUseEn: 'Prescribed neurologic or pain treatment',
    commonUseFa: 'درمان تجویزشده عصبی یا درد',
    defaultForm: MedicationForm.capsule,
  ),
  MedicationCatalogItem(
    genericName: 'Vitamin D3',
    nameFa: 'ویتامین دی ۳',
    groupEn: 'Vitamins',
    groupFa: 'ویتامین',
    commonUseEn: 'Vitamin D supplementation',
    commonUseFa: 'مکمل ویتامین D',
  ),
  MedicationCatalogItem(
    genericName: 'Ferrous sulfate',
    nameFa: 'فروس سولفات',
    groupEn: 'Minerals',
    groupFa: 'مواد معدنی',
    commonUseEn: 'Iron supplementation',
    commonUseFa: 'مکمل آهن',
  ),
  MedicationCatalogItem(
    genericName: 'Hydrocortisone',
    nameFa: 'هیدروکورتیزون',
    groupEn: 'Dermatology',
    groupFa: 'پوست',
    commonUseEn: 'Skin inflammation',
    commonUseFa: 'التهاب پوستی',
    defaultForm: MedicationForm.cream,
  ),
  MedicationCatalogItem(
    genericName: 'Insulin',
    nameFa: 'انسولین',
    groupEn: 'Diabetes',
    groupFa: 'دیابت',
    commonUseEn: 'Insulin therapy',
    commonUseFa: 'درمان با انسولین',
    defaultForm: MedicationForm.injection,
  ),
  MedicationCatalogItem(
    genericName: 'Methotrexate',
    nameFa: 'متوترکسات',
    groupEn: 'Autoimmune / rheumatology',
    groupFa: 'خودایمنی و روماتولوژی',
    commonUseEn: 'Specialist-prescribed treatment for inflammatory conditions',
    commonUseFa: 'درمان برخی بیماری‌های التهابی با تجویز متخصص',
    safetyFa:
        'ممکن است تهوع، ناراحتی گوارشی و خستگی ایجاد کند. تب، کبودی غیرعادی، زردی یا سرفه و تنگی نفس مداوم نیازمند بررسی فوری پزشکی‌اند. برنامه مصرف را دقیقاً از نسخه ثبت کنید؛ فاصله مصرف را خودسرانه تغییر ندهید.',
    safetyEn:
        'Nausea, digestive upset and fatigue can occur. Fever, unusual bruising, jaundice or persistent cough and breathlessness need urgent medical advice. Record the prescribed schedule exactly; do not change dosing intervals yourself.',
    sourceUrl:
        'https://www.nhs.uk/medicines/methotrexate/side-effects-of-methotrexate/',
    checkedOn: '2026-09-20',
  ),
  MedicationCatalogItem(
    genericName: 'Tacrolimus',
    nameFa: 'تاکرولیموس',
    groupEn: 'Transplant / kidney care',
    groupFa: 'پیوند و مراقبت کلیه',
    commonUseEn:
        'Prevention of transplant rejection under specialist supervision',
    commonUseFa: 'پیشگیری از رد پیوند زیر نظر متخصص',
    defaultForm: MedicationForm.capsule,
    safetyFa:
        'با کاهش فعالیت ایمنی، خطر عفونت شدید و بعضی سرطان‌ها افزایش می‌یابد. تب، گلودرد یا نشانه‌های عفونت را فوراً به پزشک اطلاع دهید. مصرف و پایش این دارو باید زیر نظر تیم پیوند باشد.',
    safetyEn:
        'Immune suppression increases the risk of serious infections and some cancers. Report fever, sore throat or infection symptoms immediately. Treatment and monitoring require a transplant specialist.',
    sourceUrl: 'https://medlineplus.gov/druginfo/meds/a601117.html',
    checkedOn: '2026-09-20',
  ),
  MedicationCatalogItem(
    genericName: 'Warfarin',
    nameFa: 'وارفارین',
    groupEn: 'Cardiovascular / anticoagulant',
    groupFa: 'قلب و عروق و ضدانعقاد',
    commonUseEn: 'Prevention or treatment of blood clots',
    commonUseFa: 'پیشگیری یا درمان لخته خون',
    safetyFa:
        'مهم‌ترین خطر، خونریزی است. خون در ادرار یا مدفوع، استفراغ خونی یا سردرد شدید همراه علائم عصبی نیازمند رسیدگی فوری است. دوز با آزمایش و نظر پزشک تنظیم می‌شود؛ دوره ثابت عمومی ندارد.',
    safetyEn:
        'Bleeding is the key risk. Blood in urine or stools, vomiting blood, or severe headache with neurological symptoms needs urgent care. Dose and duration are individualized using monitoring and clinical advice.',
    sourceUrl: 'https://www.nhs.uk/medicines/warfarin/',
    checkedOn: '2026-09-20',
  ),
];
