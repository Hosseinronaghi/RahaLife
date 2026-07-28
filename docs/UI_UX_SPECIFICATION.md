# Raha Life UI/UX Specification — v0.2

## Product principles

- Persian-first RTL and complete English LTR support.
- Material Design 3 foundation with a premium, calm, minimal visual language.
- Emerald is the default accent; blue, purple, and orange are selectable.
- Only sections containing data appear on the daily dashboard.
- One unified empty state replaces repeated empty cards.
- Every visible action must work. Unfinished modules are explicitly marked “Coming soon”.
- Mobile uses bottom navigation; wider layouts use a responsive navigation rail.

## Typography

- Persian: Vazirmatn through the `google_fonts` integration.
- English: Inter through the `google_fonts` integration.
- User-selectable text scaling from 90% to 120%.

## Core screens implemented in v0.2

- Dual-calendar daily dashboard
- Month, week, and day calendar views
- Global search with filters
- Active module grid and per-module lists
- Statistics and progress dashboard
- Appearance and home-layout settings
- Profile guest state
- AI provider settings
- Explicit coming-soon experience

## Interaction rules

- Tap an entry to open details.
- Toggle completion from lists and dashboard cards.
- Delete from the details sheet.
- Add entries through the quick-add menu or module-specific FAB.
- Persist language, theme, accent, text scale, and hidden home sections.
