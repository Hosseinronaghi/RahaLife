# Validation — Raha Life 0.8.0+15

Executed 2026-09-15 on an isolated Linux workspace. Source is derived from the user's complete 0.7 ZIP, with the matching changed-files ZIP compared beforehand.

| Gate | Result | Scope |
|---|---|---|
| Dependency resolution + localization/code generation | Passed | Flutter 3.47.0, Dart 3.13.0; committed pubspec.lock |
| `flutter analyze --no-pub --fatal-infos` | Passed: no issues | Product source, test source and tools |
| `flutter test --no-pub --reporter expanded` | Passed: 50 cases | Existing tests plus stale-write/causal safety, v6→7 SQLite migration, recurrence, large-text layouts and 3 rendered UI captures |
| `dart run tool/domain_smoke.dart` | Passed: 14 checks | Production domain classes: clocks, medication boundaries, account transfers and cash flow |
| PHP syntax | Passed: 3 files | Actual PHP 8.3 WASM token parser, TOKEN_PARSE: index/accounts/protocol |
| PHP protocol unit checks | Passed: 8 checks | Actual PHP 8.3 WASM execution of production pure helpers; no MySQL |
| `python tool/test_legacy_recovery.py` | Passed: 2 cases | Isolated legacy SQLite recovery and rejected overwrite |
| Flutter release web build | Passed | JavaScript release bundle with local web resources; initial Wasm compatibility dry run also compiled successfully |
| Visual inspection | Completed for Today | Real Flutter raster captures, Persian font, mobile light/dark and desktop; demonstration agenda, not live user data |
| HTTP/MySQL integration | Prepared, not executed | `server/tests/http_smoke.py`, `.github/workflows/server-ci.yml` |
| Native installation/signing/notifications/widget | Not executed | Requires device/platform SDKs and owner signing setup |
| Real AI APIs and external backup providers | Not executed | Requires selected endpoints and test credentials |

50 Flutter cases comprise 47 functional/layout cases plus 3 image-render cases. Render captures check for layout exceptions and export images; they are not pixel-baseline golden comparisons or interactive end-to-end tests.

## Reproduce

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter analyze --no-pub --fatal-infos
flutter test --no-pub --reporter expanded
dart run tool/domain_smoke.dart
python tool/test_legacy_recovery.py
php server/tests/protocol_test.php
bash tool/prepare_drift_web.sh
flutter build web --no-pub --no-web-resources-cdn --no-wasm-dry-run
```

Linux needs a loadable `libsqlite3.so`, normally installed through `libsqlite3-dev`. This workspace used a temporary symlink to the installed system `libsqlite3.so.0` and set `LD_LIBRARY_PATH` for native tests. Flutter commands ran with `CI=true`. No workspace-specific SDK or library symlink is included in source.

Code generation emitted legacy Drift table-reference warnings and a Dart/analyzer language-version warning; generated code still compiled and the final analyzer gate passed. Some pure controller tests logged caught notification-plugin initialization errors because native platform plugins do not exist in that test runner. Therefore passing those tests does not certify OS notification delivery.

No production deployment, database migration against real user records or signed binary distribution was performed. Before production, close the P0 acceptance rows in `RELEASE_0.8_FA.md`.

Final web build completed in 55.0 seconds. The delivery ZIP also contains `Raha-Life-Web/`, the precompiled static web output, for local HTTP preview without installing Flutter.
