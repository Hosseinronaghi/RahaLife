# راه‌اندازی Dropbox برای ناشر رها

این ثبت فقط یک بار توسط ناشر انجام می‌شود؛ کاربران صرفاً روی «اتصال به Dropbox» می‌زنند و در صفحه رسمی سرویس وارد می‌شوند. رمز حساب و client secret وارد رها نمی‌شوند.

۱. در https://www.dropbox.com/developers/apps یک Scoped App با دسترسی **App Folder** بسازید؛ Full Dropbox انتخاب نشود.
۲. مجوزهای account_info.read، files.metadata.read، files.content.read و files.content.write را فعال کنید.
۳. آدرس‌های بازگشت زیر را ثبت کنید:
- Android، iOS، macOS: `com.raha.life.oauth:/callback`
- Windows، Linux: `http://127.0.0.1:43829/callback`
- Web: آدرس HTTPS دقیق `auth.html` کنار برنامه؛ مثلاً `https://YOUR-DOMAIN/raha/auth.html`. باید هم‌مبدأ با برنامه باشد. نمونه را با دامنه واقعی جایگزین کنید.
۴. در GitHub → Settings → Secrets and variables → Actions → Variables، مقدار App key را در RAHA_DROPBOX_CLIENT_ID و نشانی وب را در RAHA_DROPBOX_WEB_REDIRECT_URI قرار دهید. Client secret لازم نیست و نباید در سورس یا این متغیرها قرار گیرد.
۵. گردش Build را دوباره اجرا کنید. پیکربندی هر پلتفرم خودکار ساخته می‌شود. بدون این مقادیر، دکمه ورود مستقیم غیرفعال و علت برای کاربر نمایش داده می‌شود.
۶. محدودیت کاربران آزمایشی و وضعیت production اپ Dropbox را در کنسول همان سرویس مدیریت کنید.

## رفتار و محدودیت
- Authorization Code + PKCE/S256، state تصادفی، بررسی دقیق نشانی برگشت، جلوگیری از استفاده مجدد، انقضای تلاش پس از ۱۰ دقیقه.
- مرورگر رسمی سیستم؛ WebView داخلی برای ورود استفاده نمی‌شود. Windows/Linux از loopback محلی استفاده می‌کنند.
- access/refresh token در Secure Storage؛ تازه‌سازی توکن بین عملیات هم‌زمان هماهنگ است.
- بکاپ رمزگذاری‌شده موجود رها در پوشه اختصاصی اپ ذخیره می‌شود؛ نام یکتا از بازنویسی فایل دستگاه دیگر جلوگیری می‌کند.
- آخرین فایل بر اساس زمان سرور و همه صفحات فهرست انتخاب می‌شود. دانلود به revision معین متصل است و فایل ناقص رد می‌شود.
- حد هر بکاپ در این مسیر ۱۴۰ MiB است؛ فایل بزرگ‌تر به مسیر دیگری نیاز دارد. پاک‌سازی خودکار نسخه‌های قدیمی اضافه نشده است.
- این مسیر **Backup/Restore** است؛ Sync رکوردی روی Dropbox هنوز پیاده نشده.
- حذف اتصال در رها اعتبارنامه محلی را حذف می‌کند؛ برای لغو دسترسی سرویس، از Connected apps خود Dropbox استفاده کنید. فایل‌های قبلی خودکار پاک نمی‌شوند.
- نسخه وب به HTTPS، پیکربندی صحیح origin و callback و اجازه popup نیاز دارد. روی http://localhost این مسیر فعال نمی‌شود؛ خود اپ و بکاپ دستی مستقل‌اند.
- ورود واقعی، انتقال و بازیابی باید پس از ثبت اپ با حساب آزمایشی روی هر پلتفرم آزموده شوند. تست HTTP شبیه‌سازی‌شده جای این پذیرش را نمی‌گیرد.

## ساخت محلی
متغیرهای عمومی بالا را در محیط build تنظیم کنید، سپس:

```sh
python tool/write_oauth_build_config.py web
flutter build web --release --dart-define-from-file=build/oauth-web.json
```
برای Android به‌جای web از android و فرمان build apk استفاده کنید. پیش از build پلتفرم‌های تولیدشده، `python tool/configure_branding.py` را اجرا کنید تا callback Android نیز اضافه شود. شناسه برنامه و امضای نسخه قبلی را تغییر ندهید.

منابع: https://docs.dropboxapi.com/dropbox-api/docs/oauth و https://pub.dev/packages/flutter_web_auth_2
