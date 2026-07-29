# Changelog

## 0.4.1+8

### Fixed
- Removed an unnecessary non-null assertion in the medication controller.
- Migrated module reordering from the deprecated `onReorder` callback to `onReorderItem`.
- Updated reorder index handling for the new Flutter callback semantics.
- Restored compatibility with `flutter analyze --fatal-infos` on current Flutter stable.

## 0.4.0+7

### Added
- Unified local reminder engine with normal notifications and prominent alarms.
- Time-zone-aware scheduling, repeat rules, exact-alarm permission handling, and notification-tap routing.
- Reminder controls for Affairs, Appointments, Birthdays, Shopping, Medicine, Bills, and estimated Cycle dates.
- Location and address fields for Affairs, Appointments, and Shopping lists.
- Scheduled shopping lists with purchase date, time, location, reminder, recurrence, and a linked Shopping Affair.
- Two-way navigation between a Shopping list and its linked Affair.
- Bill reminders with due date/time, bill type, bill/payment identifiers, paid state, and repeat schedule.
- Full default expense categories covering bills, rent, food, transport, health, medicine, education, travel, subscriptions, loans, and more.
- User-controlled module order with drag-and-drop, hide/show controls, and restore-default action.
- Daily medicine notification/alarm schedules.
- Optional reminder for the estimated next cycle date.
- Tests for reminder serialization and IDs, scheduled Shopping links, and unpaid/paid bill accounting.

### Changed
- Moved Cycle before People in the default module order.
- Rebuilt light and dark theme colors to force readable foreground colors on Android and Windows.
- Added Vazirmatn as the preferred Persian typeface with an offline Vazir fallback.
- Constrained the desktop month calendar width and cell proportions to prevent oversized selected dates.
- Updated notification permissions and Android scheduled-notification receivers in GitHub Actions.
- Updated app version to `0.4.0+7`.

### Still planned
- Server-backed account registration, password recovery, and multi-device synchronization.
- Collaborative live Shopping lists.
- User-created financial categories/subcategories, budgets, receipts, and advanced charts.
- Custom alarm sounds and snooze actions.

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
