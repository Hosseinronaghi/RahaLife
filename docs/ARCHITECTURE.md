# Architecture

## Principles

1. Offline-first: every user action commits locally first.
2. AI-optional: the whole app remains usable without AI or internet.
3. Deterministic core: medication, reminders, finance and recurrence calculations never depend on model output.
4. Provider-neutral AI: all providers implement one interface.
5. Confirmation before mutation: AI can propose actions but the app validates and asks before committing.
6. Privacy by minimization: send only the smallest required payload to online AI.

## Layers

- Presentation: Flutter widgets and Riverpod controllers
- Application: use cases and validation
- Domain: entities, value objects and rules
- Data: Drift repositories, secure storage and HTTP providers
- Infrastructure: notification, backup, Drive and future sync gateway

## Feature modules

- Today/dashboard
- Calendar (daily, weekly, monthly, yearly)
- Tasks
- Medication and adherence logs
- Appointments
- Notes and timed notes
- Shopping lists
- Finance and budgets
- Habits and streak-neutral progress
- Goals and reviews
- Reports
- AI assistant
- Backup and sync

## AI modes

- Raha Free AI through a server-side gateway and managed quota
- OpenAI API with user key
- Gemini API with user key
- Custom OpenAI-compatible endpoint

Consumer ChatGPT subscriptions are not treated as API credentials.
