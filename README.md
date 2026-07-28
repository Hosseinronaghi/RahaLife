# Raha Life — v0.3.0

Raha Life is a bilingual, offline-first personal organizer for affairs, appointments, shopping, medicine, people, birthdays, notes, habits, finance, calendars, and personal cycle tracking.

## What is working in v0.3.0

### Account and profile

- Create one local account on the current device
- Sign in and sign out
- Salted SHA-256 password hash stored in secure storage
- Persistent local session
- Guest mode remains available
- Clear in-app notice that multi-device sync is planned for the next milestone

> The current account is local. It is not yet a server account and does not sync between devices.

### People

- Dedicated People module
- Name, relationship, phone, email, birthday, and notes
- Optional birthday entry creation
- Link a person to an affair or appointment
- Show the related person in entry details

### Affairs and appointments

- “Tasks” is renamed to “Affairs” (`امور`)
- Medical, laboratory, administrative, follow-up, payment, work, study, personal, and custom categories belong to Affairs
- Appointments only describe the interaction format: meeting, cafe, gathering, in-person session, phone call, online session, party, or custom

### Shopping

- Multiple independent shopping lists
- Bulk item entry, one item per line
- Add more items later
- Check/uncheck items
- Purchased items move to the bottom
- Share the list as text through the platform share sheet
- Clipboard fallback when sharing is unavailable

### Medicine

- Dedicated medication plans instead of generic task cards
- Medicine form: tablet, capsule, syrup, drops, injection, cream, inhaler, or other
- Dose, daily time, instructions, stock, active/inactive state
- Quick “taken” feedback and plan deletion

### Finance

- Multiple financial accounts
- Opening balances
- Income, expense, transfer, debt, receivable, and saving transaction types
- Category, note, date, and account
- Filters and basic income/expense/balance summaries

### Cycle

- Private cycle records with start/end dates
- Flow intensity, pain level, mood, and notes
- Approximate next-cycle estimate based on recorded intervals
- Privacy notice and explicit estimate-only wording

### Interface and localization

- Singular Persian module names: امور، قرار، خرید، دارو، افراد، تولد، یادداشت، عادت، مالی
- Shopping and Medicine appear before Birthday
- Material Design 3 responsive interface
- Persian RTL and English LTR
- Persian digits and dual Persian/Gregorian date display
- Light, dark, and system themes
- Bundled Vazir fallback for Persian plus Vazirmatn runtime loading
- Android internet permission is generated for online AI and font loading

## GitHub Actions outputs

Open **Actions → Build Raha Life → Run workflow**. The workflow creates:

### Android

- `Raha-Life-universal-release.apk`
- `Raha-Life-arm64-v8a-release.apk`
- `Raha-Life-armeabi-v7a-release.apk`
- `Raha-Life-x86_64-release.apk`
- `Raha-Life-release.aab`

### Windows

- `Raha-Life-Windows-x64-portable.zip`

### Web

- `Raha-Life-Web-release.zip`

Each artifact package includes SHA-256 checksums.

## Repository setup

Upload the contents of this folder to the repository root. These paths must be visible directly in the repository:

```text
pubspec.yaml
lib/
test/
.github/
docs/
```

Platform projects are generated in GitHub Actions. Local setup is optional:

```bash
flutter create --platforms=android,ios,windows,macos,linux,web --org com.raha --project-name raha_life .
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
flutter test
```

## Important scope note

The account in this release is deliberately local because the cloud sync backend is the next milestone. Android, Windows, and Web synchronization, cloud recovery, conflict resolution, and collaborative shopping lists are not claimed as complete in v0.3.0.

## Delivery documents

- [v0.3.0 delivery report](docs/DELIVERY_0.3.0.md)
- [v0.3.0 validation report](docs/VALIDATION_0.3.0.md)
- [Implementation roadmap](docs/IMPLEMENTATION_ROADMAP.md)
- [UI/UX specification](docs/UI_UX_SPECIFICATION.md)
- [Changelog](CHANGELOG.md)
