# Raha Life v0.4.0+7 — Delivery Report

## Implemented

### Theme, colors, font, and calendar
- Reworked theme construction so every text style derives its color from the active `ColorScheme`.
- Added explicit readable colors for navigation, cards, forms, dialogs, chips, date/time pickers, and buttons.
- Persian theme prefers Vazirmatn and uses the bundled Vazir package theme as an offline fallback.
- Constrained the Windows/Desktop month calendar to 760 pixels and corrected cell proportions.

### Module layout
- Cycle now appears before People by default.
- Added persisted drag-and-drop module ordering.
- Added persisted hide/show controls and restore-default behavior.

### Location
- Added location and address to Affairs and Appointments.
- Added store/location and address to Shopping lists.
- Added location/address display in details.

### Notifications and alarms
- Added a shared `ReminderPlan` model.
- Added notification and alarm modes.
- Added once/daily/weekly/monthly/yearly rules.
- Added time-zone-aware scheduling.
- Added Android notification, exact-alarm, full-screen-intent, vibration, and reboot receiver setup.
- Added settings controls for permission requests and test notification/alarm.
- Added notification-tap routing to Shopping, Finance, Medicine, and Cycle.

### Shopping
- Added purchase date and time.
- Added location and address.
- Added reminder type, offset, and recurrence.
- Added automatic optional creation of an Affair of type Shopping.
- Added bidirectional IDs between Shopping list and Affair.
- Notification tap opens the linked Shopping list.

### Finance and bills
- Added Bill transaction type.
- Added bill type, identifiers, due date/time, reminder, recurrence, and paid status.
- Added complete default expense-category list.
- Unpaid bills are excluded from expense totals until marked paid.
- Marking a bill paid cancels its pending reminder.

### Medicine
- Added daily notification/alarm settings to medication plans.
- Added reminder persistence and migration-safe JSON decoding.
- Disabling/deleting medicine cancels its scheduled reminder.

### Cycle
- Added optional reminder for the estimated next-cycle date.
- Added reminder mode, reminder days before, and reminder time.
- Reminder is cancelled when its source cycle record is deleted.

## Not implemented yet
- Remote/server account and real password recovery.
- Android ↔ Windows ↔ Web sync.
- Collaborative real-time Shopping.
- Custom Finance categories and icons.
- Budgets, savings goals, receipts, recurring-transaction engine, and advanced charts.
- User-selectable alarm sounds and interactive Snooze buttons.
- Map picker and geofenced reminders.

## Version
- Package version: `0.4.0+7`
