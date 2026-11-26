# پشتیبان Google Drive و iCloud

- **Google Drive در ویندوز و لینوکس:** Drive API را در Google Cloud فعال کنید، یک OAuth Client از نوع Desktop app بسازید و شناسهٔ عمومی آن را در GitHub Actions Variables با نام `RAHA_GOOGLE_DRIVE_CLIENT_ID` بگذارید. در بستهٔ جدید، ورود با مرورگر سیستم و PKCE از نشانی بازگشت `http://127.0.0.1:43829/callback` انجام می‌شود. فایل‌ها در فضای خصوصی `appDataFolder` نگه‌داری می‌شوند و در ریشهٔ Drive دیده نمی‌شوند. از ثبت دسترسی کل درایو یا قرار دادن رمز در مخزن خودداری کنید. ورود با حساب واقعی باید روی بستهٔ دارای شناسهٔ ناشر آزموده شود.
- **iCloud در آیفون و مک:** در Apple Developer برای شناسهٔ بستهٔ فعلی، iCloud Documents و یک شناسهٔ container از نوع `iCloud.…` تنظیم کنید؛ شناسهٔ بسته را عوض نکنید. هنگام تولید پروژهٔ Apple، مقدار غیرمحرمانهٔ `RAHA_ICLOUD_CONTAINER` را به `tool/configure_apple_platforms.py` بدهید. همان container باید در گواهی/پروفایل و قابلیت‌های هدف مجاز باشد. سپس بستهٔ توزیع امضاشده را بسازید و روی دستگاهی که حساب iCloud فعال دارد آزمایش کنید. ساخت پیش‌نمایش بدون entitlement نیز ممکن است ولی اتصال iCloud را تأیید نمی‌کند.
- iCloud فعلاً سقف ۳۲ مگابایت برای هر فایل دارد. برای فایل بزرگ‌تر از خروجی دستی استفاده کنید. وقتی آخرین فایل هنوز روی دستگاه دانلود نشده، پس از تکمیل دانلود دوباره بازیابی را بزنید.
- هر دو مقصد فقط فایل پشتیبان رمزگذاری‌شدهٔ رها را منتقل می‌کنند. کلید بازیابی را جدا نگه دارید. این اتصال‌ها همگام‌سازی سرتاسری رکوردها یا رمزنگاری پیام را فعال نمی‌کنند.

مراجع رسمی: [Google Desktop OAuth](https://developers.google.com/identity/protocols/oauth2/native-app)، [Google Drive appDataFolder](https://developers.google.com/workspace/drive/api/guides/appdata)، [iCloud Documents](https://developer.apple.com/documentation/uikit/synchronizing-documents-in-the-icloud-environment).

## ساخت دارای امضای رسمی

گردش **Sign Raha Life for Apple devices** فقط دستی، روی `main` و داخل GitHub Environment با نام `apple-release` اجرا می‌شود. محیط را محدود به `main` و با بازبینی اجرای دستی بسازید. فایل کلید یا گواهی را در گفت‌وگو یا مخزن قرار ندهید.

| هدف | متغیرهای ناشر | اسرار داخل محیط |
|---|---|---|
| مشترک | `RAHA_APPLE_TEAM_ID`؛ در صورت نیاز `RAHA_ICLOUD_CONTAINER` | — |
| IPA برای دستگاه‌های ثبت‌شده | — | `RAHA_IOS_P12` (Base64)، `RAHA_IOS_P12_PASSWORD`، `RAHA_IOS_PROFILE` (Base64 از پروفایل Ad Hoc) |
| DMG مک و notarization | `RAHA_NOTARY_KEY_ID`، `RAHA_NOTARY_ISSUER` | `RAHA_MAC_P12` (Base64 Developer ID Application)، `RAHA_MAC_P12_PASSWORD`، `RAHA_NOTARY_API_KEY` (Base64 فایل p8)؛ اگر iCloud فعال است `RAHA_MAC_PROFILE` (Base64 پروفایل Developer ID) |

ساخت IPA برای TestFlight یا App Store مرحلهٔ جداست. این گردش هیچ خروجی‌ای را خودکار منتشر نمی‌کند؛ بستهٔ امضاشده و هش آن فقط پس از موفقیت در Artifacts قرار می‌گیرند. برای بررسی اعلان‌ها، روی دستگاه فیزیکی از [چک‌لیست دستگاه](DEVICE_VALIDATION_FA.md) با یک حساب آزمایشی استفاده کنید.
