# Raha Life Design System v2 — foundation

v0.7 introduces the foundation of the second visual system. This is the first rollout, not the final redesign of every feature screen.

## Shared visual language

`lib/app/design_system/raha_tokens.dart` defines shared spacing, radius and motion tokens plus module visual identities.

`lib/app/design_system/raha_surfaces.dart` introduces reusable premium surfaces:

- `RahaSurface`
- `RahaHeroPanel`
- `RahaMetricTile`

The global Material 3 theme uses the new radii/control conventions for cards, buttons, chips, sheets, checkboxes, icon buttons and progress indicators.

## Module identity

The product keeps one design language while allowing topic-specific accents for Affairs, Appointment, Shopping, Medication, Cycle, People, Birthday, Notes, Projects, Finance and Messages.

## v0.7 visible rollout

Today is the first main screen migrated to the v2 system:

- graphical date hero panel;
- module-accented summary surfaces;
- metric tiles;
- animated progress;
- richer section hierarchy and subtle graphical glow;
- the existing conditional-data behavior remains unchanged.

Future releases should migrate modules one by one after their data model is stable, rather than redesigning unstable screens twice.
