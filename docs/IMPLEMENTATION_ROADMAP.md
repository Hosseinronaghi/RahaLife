# Implementation roadmap

## Completed foundation — v0.1 to v0.4

- Flutter responsive application shell
- Persian/English localization and RTL/LTR
- Material 3 themes and personalization
- Today dashboard, calendar, global search, and basic reports
- Affairs, appointments, notes, habits, birthdays
- Dedicated People, Shopping, Medicine, Finance, and Cycle modules
- Functional local account and session
- Optional online AI provider settings
- Android, Windows, and Web GitHub build workflows
- Cross-platform notification/alarm foundation with repeat rules
- Scheduled Shopping linked to Affairs
- Bill reminders and full default expense categories
- User-customizable module order and visibility
- Location/address fields for Affairs, Appointments, and Shopping
- Daily Medicine reminders and estimated Cycle reminders

## Next milestone — server account and synchronization

### Account backend

- Server-backed registration and login
- Email verification
- Password reset
- Refresh-token/session lifecycle
- Device list and remote sign-out
- Account deletion and data export

### Cross-device sync

- Android, Windows, and Web synchronization
- Per-entity change queue
- Soft-delete tombstones
- Server revision and client revision
- Offline writes and retry policy
- Conflict-resolution screen
- Last-sync status and failure details
- Selective module sync

### Collaborative shopping

- Invite a person to a shopping list
- Owner, editor, and viewer roles
- Real-time or near-real-time item updates
- Show who added or checked an item
- Activity history and notifications

## Finance milestone

- Destination account for transfers
- Account types and currencies
- Categories and subcategories
- Recurring transactions
- Debt/receivable counterparties linked to People
- Budgets and category limits
- Saving goals
- Receipt images and attachments
- Monthly/yearly charts and exports

## Medicine and reminder milestone

- Multiple schedules per medicine
- Recurrence rules and date ranges
- Taken, late, skipped, missed, and postponed logs
- Actionable notifications
- Stock decrement and refill warnings
- Expiration warnings
- Doctor/report export

## Cycle milestone

- Symptom selection and daily logs
- Calendar visualization
- Reminder privacy controls
- Optional fertility features, disabled by default
- Encrypted/private-module controls
- Backup inclusion toggle

## Later collaboration

- Shared Affairs
- Shared calendar
- Shared notes
- Messaging
- Email sharing
