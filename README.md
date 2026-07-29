# Raha Life — v0.4.1

Raha Life is a bilingual, offline-first personal organizer for Affairs, Appointments, Shopping, Medicine, Cycle tracking, People, Birthdays, Notes, Habits, and personal Finance.

## What changed in v0.4.1

### Readable colors and Persian typography

- Rebuilt Material 3 light/dark color handling for Android and Windows.
- Explicit foreground colors for cards, navigation, forms, dialogs, date/time pickers, chips, and buttons.
- Vazirmatn remains the preferred Persian font.
- Bundled Vazir from `persian_fonts` is used as an offline fallback when runtime Vazirmatn is not yet available.
- Desktop calendar width and day-cell proportions are constrained so selected dates do not become oversized.

### Notifications and alarms

Two reminder modes are available:

- Standard notification
- Prominent alarm with maximum importance, vibration, sound, and Android full-screen intent

Supported repeat rules:

- Once
- Daily
- Weekly
- Monthly
- Yearly

Reminder taps open the relevant screen for Shopping, Bills, Medicine, and Cycle. General Affairs and Appointments return to the daily dashboard.

### Location

Location and address can be recorded for:

- Affairs
- Appointments
- Shopping lists

These values are also shown in item details.

### Scheduled Shopping linked to Affairs

A Shopping list can include:

- Purchase date
- Purchase time
- Store/location
- Address
- Notification or alarm
- Reminder offset
- Repeat schedule

When **Link Shopping to Affair** is enabled, Raha Life creates an Affair of type Shopping and links both records. The reminder opens the actual Shopping list so items can be checked.

### Bills and Finance categories

Bill records now support:

- Bill type
- Amount
- Account
- Due date and time
- Bill identifier
- Payment identifier
- Notification or alarm
- Reminder offset and recurrence
- Paid/unpaid state

Unpaid bills are not counted as completed expenses until they are marked paid.

Default expense categories include bills, rent/housing, groceries, restaurant/cafe, transport, fuel, health, medicine, daily shopping, education, entertainment, travel, clothing, internet/phone, insurance, tax, loans/installments, subscriptions, repairs, gifts, family, pets, charity, and other.

### Medicine

Medication plans now include an optional daily notification or alarm at the selected time. Disabling or deleting a medicine cancels its reminder.

### Cycle

Cycle appears before People in the default module order. A cycle record can optionally schedule a reminder before the estimated next cycle date. The estimate remains explicitly non-diagnostic and approximate.

### Personalized module order

From **Settings → Module order**, the user can:

- Reorder modules using drag and drop
- Hide or show each module
- Restore the default order

Default order:

```text
Affairs
Appointment
Shopping
Medicine
Cycle
People
Birthday
Note
Habit
Finance
```

## Account and synchronization status

The local account from v0.3.0 remains available. It is not yet a server account. Android, Windows, Web, and other-device synchronization is the next cloud milestone and is not claimed as complete in this release.

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

Scheduled local notifications are currently enabled for native targets; the Web build does not schedule local reminders in this milestone.

## Repository setup

Extract the complete source and upload its contents to the repository root. `pubspec.yaml` must be directly visible in the repository.

```bash
flutter create --platforms=android,ios,windows,macos,linux,web --org com.raha --project-name raha_life .
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
flutter test
```

## Delivery documents

- [v0.4.0 delivery report](docs/DELIVERY_0.4.0.md)
- [v0.4.0 validation report](docs/VALIDATION_0.4.0.md)
- [Implementation roadmap](docs/IMPLEMENTATION_ROADMAP.md)
- [UI/UX specification](docs/UI_UX_SPECIFICATION.md)
- [Changelog](CHANGELOG.md)
