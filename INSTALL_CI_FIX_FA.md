# رفع خطای پوشه تکراری — CI Fix 2

## علت گزارش جدید
همه مسیرهای خطا در لاگ جدید به lib/app/app اشاره دارند. مسیر درست lib/app است.
آپلود دوباره فایل‌های درست، فایل‌های اضافی قبلی را حذف نمی‌کند؛ حذف پوشه تکراری ضروری است.

## روش پیشنهادی: GitHub Desktop
1. مخزن Hosseinronaghi/RahaLife را در GitHub Desktop باز یا Clone کنید.
2. از Repository > Show in Explorer پوشه محلی مخزن را باز کنید.
3. بسته کامل را استخراج کنید. محتویاتش را در ریشه مخزن جایگزین کنید، همان جایی که pubspec.yaml قرار دارد. پوشه .github را هم کپی کنید. پوشه .git مخزن را دست نزنید.
4. اکنون lib/app/app را از مخزن خارج کنید و برای احتیاط در پوشه‌ای بیرون مخزن نگه دارید. lib/app/app.dart، lib/app/router.dart، lib/app/theme.dart و lib/app/shell/responsive_shell.dart باید باقی بمانند.
5. در GitHub Desktop باید حذف فایل‌های مسیر lib/app/app/ در Changes دیده شود.
6. Commit to main و سپس Push origin را بزنید. اگر شاخه دیگری دارید از همان شاخه و روال ادغام مخزن استفاده کنید.
7. اجرای جدید Build Raha Life را در Actions باز کنید. اجرای قدیمی را Re-run نکنید چون همان commit قدیمی را دوباره می‌سازد.

## روش مرورگر
1. تب Code و ریشه مخزن را باز کنید؛ وارد lib یا lib/app نشوید.
2. Add file > Upload files را بزنید و محتویات استخراج‌شده را با ساختار پوشه‌هایشان وارد کنید. خود ZIP را آپلود نکنید.
3. در صورت استفاده از بسته تغییرات، فقط tool و INSTALL_CI_FIX_FA.md تغییر می‌کنند؛ این بسته نسبت به CI-Fix قبلی است و جایگزین سورس ناقص نیست.
4. در تب Code فایل‌های اضافی زیر را پیدا کرده و از منوی فایل Delete file را انتخاب و حذف‌ها را Commit کنید:
   lib/app/app/app.dart
   lib/app/app/router.dart
   lib/app/app/theme.dart
   lib/app/app/shell/responsive_shell.dart
   هر فایل دیگری در پوشه تکراری را قبل از حذف بررسی کنید. مسیرهای درست یک app کمتر دارند.
5. اگر آپلود از مرورگر ناقص شد یا حجم/تعداد فایل‌ها محدود شد، از GitHub Desktop استفاده کنید.

## ترمیم خودکار اختیاری با Python
از ریشه مخزن:
python tool/repair_nested_app.py
این دستور فقط پیش‌نمایش است. اگر فایل‌ها مطابق نسخه شناخته‌شده باشند:
python tool/repair_nested_app.py --apply
python tool/check_source_integrity.py
اسکریپت پوشه تکراری را بیرون مخزن بکاپ می‌گیرد و فایل صحیحِ مفقود را برمی‌گرداند. در برخورد با فایل ناشناخته یا متفاوت متوقف می‌شود و چیزی حذف نمی‌کند.

## Commit changes
Summary:
fix: remove nested app upload and detect duplicate source files

Description:
Restore the correct lib/app directory layout and remove accidental lib/app/app copies.
Detect unexpected Dart files before Flutter analysis.
Add a guarded repair utility with an external backup and upload instructions.

## وضعیت اعتبارسنجی
کنترل یکپارچگی سورس و تست‌های اسکریپت ترمیم در محیط Python انجام می‌شوند.
Flutter analyze، Flutter test و ساخت APK/Windows در این نوبت اجرا نشده‌اند؛ SDK در محیط موجود نیست.
این بسته بر مبنای بسته کامل CI-Fix قبلی است؛ خود مخزن آنلاین دریافت یا تغییر داده نشده است.
پک تغییرات فقط اختلاف با Raha-Life-v0.8.0-CI-Fix.zip را دارد. حذف فایل‌های اضافی باید جداگانه انجام شود؛ ZIP حذف را اعمال نمی‌کند.
