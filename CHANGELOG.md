# Changelog

## 0.3.0+6

### Added
- Functional local account creation, sign-in, sign-out, secure salted password hashing, and persistent local session.
- Dedicated People module with contact information, birthday, notes, and links to affairs and appointments.
- Dedicated shopping-list model with multiple lists, bulk item entry, check states, sorting, and text sharing.
- Dedicated medication model with medicine form, dosage, time, instructions, stock, and active state.
- Expanded finance model with accounts, opening balances, six transaction types, categories, notes, filters, and summaries.
- Initial private cycle-tracking module with flow, pain, mood, notes, and approximate next-cycle estimation.
- People and user-profile tables in the Drift schema.
- Affairs and cycle-log tables/fields in the Drift schema.
- Medication and finance controller tests.
- Android release internet permission generation for online services and runtime font loading.

### Changed
- Renamed Tasks to Affairs (`امور`) throughout the active UI and data model.
- Moved medical, laboratory, administrative, follow-up, and payment classifications to Affairs.
- Limited Appointment types to meeting formats such as cafe, gathering, in-person, phone, and online.
- Changed Persian module labels to singular forms.
- Reordered modules so Shopping and Medicine appear before Birthday.
- Updated More and Profile screens to reflect the current local account.
- Upgraded the local database schema scaffold to version 3.
- Updated app version to `0.3.0+6`.

### Deferred to the next milestone
- Real server-backed registration and password recovery.
- Android, Windows, and Web synchronization.
- Cloud backup and new-device recovery.
- Collaborative real-time shopping lists.
- Conflict resolution and sync history.

## 0.2.0+5

### Added
- Complete Material 3 visual redesign for mobile and desktop.
- Persian-first RTL layout and English LTR layout.
- Vazirmatn and Inter typography integration.
- Dynamic light, dark, and system themes.
- Emerald, blue, purple, and orange accent choices.
- Persistent language, theme, accent, text scale, and home section settings.
- Redesigned daily dashboard with dual Persian/Gregorian date header.
- Conditional dashboard sections and a unified empty state.
- Working quick add for tasks, medicines, appointments, notes, shopping, finance, habits, and birthdays.
- Entry details, completion toggle, and deletion.
- Global search with type filters.
- Month, week, and day calendar views.
- Active module pages and explicit coming-soon pages.
- Statistics and progress views.
- Birthday database table and repeated birthday date logic.
- Functional AI settings persistence and OpenAI-compatible connection test.
