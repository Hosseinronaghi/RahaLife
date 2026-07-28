# Raha Life v0.3.0+6 — Delivery report

## Delivery objective

This delivery implements the decisions made after v0.2.0: introduce a functional account foundation, add People, separate Affairs from Appointment formats, place Shopping and Medicine before Birthday, create real multi-item shopping lists, give Medicine and Finance dedicated data structures, and add the first private Cycle module.

## Implemented

### 1. Local account foundation

- Create a local account with full name, email, and password.
- Validate email and require a minimum eight-character password.
- Generate a random salt and save only a salted SHA-256 hash in secure storage.
- Save profile metadata and session state locally.
- Sign in and sign out.
- Keep guest mode available.
- Show account identity in More and Profile.
- Explicitly label synchronization as a next-version feature.

This is a functional device-local account, not a cloud account. A server endpoint and email delivery service are intentionally not fabricated in this release.

### 2. People

- Add, list, inspect, and delete people.
- Save relationship, phone, email, birthday, and notes.
- Create a recurring Birthday entry when a birthday is supplied.
- Select a related person while creating an Affair or Appointment.
- Display the related person in entry details.

### 3. Affairs

The former Tasks module is now Affairs (`امور`). Its classifications are:

- Personal
- Work
- Administrative
- Follow-up
- Medical
- Laboratory
- Payment and renewal
- Study
- Custom

Medical and administrative subjects are no longer Appointment types.

### 4. Appointment

Appointment now describes the interaction format only:

- Meeting
- Cafe
- Gathering
- In-person session
- Phone call
- Online session
- Party
- Custom

### 5. Shopping

- Create multiple named shopping lists.
- Enter multiple items at once, one per line.
- Add more items later.
- Check and uncheck items.
- Sort checked items below active items.
- Delete a list.
- Share a list as text through the operating-system share interface.
- Copy the generated text to the clipboard when system sharing fails.

Real-time collaborative sharing requires the next synchronization milestone.

### 6. Medicine

- Dedicated medication plan model and screen.
- Medicine name and form.
- Dosage and daily time.
- Instructions and optional stock.
- Active/inactive toggle.
- Quick taken feedback.
- Delete medication plan.

### 7. Finance

- Create multiple accounts.
- Save an opening balance.
- Record income, expense, transfer, debt, receivable, and saving.
- Save account, category, note, and date.
- Filter by transaction type.
- Show income, expense, and balance summaries.
- Delete a transaction with a long press.

This is the next foundation layer; destination-account transfer logic, budgets, savings goals, receipt attachments, and advanced charts remain on the roadmap.

### 8. Cycle

- Add cycle start and optional end date.
- Save flow intensity, pain score, mood, and notes.
- Estimate the next start date from recorded intervals, constrained to a reasonable display range.
- Present the result explicitly as an estimate.
- Show privacy and non-diagnostic wording.

### 9. Naming and order

Active Persian module names are singular and consistent:

- امور
- قرار
- خرید
- دارو
- افراد
- تولد
- یادداشت
- عادت
- مالی
- چرخه

Shopping and Medicine are placed before Birthday.

### 10. Font handling

- Added a bundled Persian-font package as a reliable offline fallback.
- Kept Vazirmatn through `google_fonts` for the requested Persian appearance.
- Enabled Android internet access in the generated release project so runtime font loading and online AI connections can work.
- No font binary is included in the delivery archive outside dependency resolution.

### 11. Automation and data scaffold

- Build workflows still target Android APK/AAB, Windows portable, and Web ZIP.
- Android desugaring and Java 17 remain configured.
- Database schema scaffold advanced to version 3.
- Added People, UserProfiles, Affairs, and CycleLogs structures and new type fields.
- Added controller tests for People, Shopping, Medication, Finance, Cycle, Home entries, locale formatting, and Money.

## Not implemented or claimed in this delivery

- Server-backed registration
- Email verification
- Password reset email
- Cross-device sync
- Cloud backup
- Google Sign-In
- Shared live shopping lists
- Multi-user permissions
- Sync conflict resolution
- Production notification scheduling

These are the next milestone, not hidden inactive controls.
