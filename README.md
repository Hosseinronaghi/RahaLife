# Raha Life — 0.8.0+15 (review candidate)

Persian/English, local-first life organizer built with Flutter. This source delivery includes a working release web build configuration, upgraded record synchronization, revised responsive UI and expanded feature screens. It is a development review candidate, not a certified production release.

**Persian change report, scope and remaining acceptance work:** [docs/RELEASE_0.8_FA.md](docs/RELEASE_0.8_FA.md)

**Executed checks:** [docs/VALIDATION_0.8.md](docs/VALIDATION_0.8.md)

## Run

Validated with Flutter 3.47.0 / Dart 3.13.0. Use the committed dependency lockfile. On Linux, native SQLite tests require `libsqlite3-dev` (providing `libsqlite3.so`).

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build
bash tool/prepare_drift_web.sh
flutter analyze --fatal-infos
flutter test
flutter run -d chrome
```

For missing platform scaffolds, `bash tool/bootstrap.sh` generates supported platforms and runs setup and checks. Review generated platform settings before release. Android production upgrades require your original signing key; see `docs/ANDROID_RELEASE_SIGNING.md`. Apple platform setup is in `tool/configure_apple_platforms.py`.

```bash
flutter build web --no-web-resources-cdn
```

Serve `build/web/` through an HTTP server; opening index.html via `file://` is unsupported. No hosted deployment is included. Source UI captures with isolated demo data are in `docs/ui/`; regenerate via `flutter test test/ui_capture_test.dart`.

## Data and hosting

Local schema 7 uses entity documents, durable changes, tombstones and vector clocks. Upload acknowledgements reference exact change IDs; concurrent record edits become conflicts. Backups contain logical records and merge conservatively. Keep a separate recovery key and test restoration before replacing a real installation.

Server **protocol 3** requires the matching PHP code and database upgrade. See [server/shared-hosting/README.md](server/shared-hosting/README.md). Old architecture documents describe historical releases and do not override the 0.8 report.

Supported record sync: the bundled Raha server or a compatible HTTPS API. WebDAV, Nextcloud, S3 and SFTP are backup targets. OS file-provider flows do not imply direct OAuth live sync with cloud providers.

## Validation boundaries

No APK/IPA or production signing was produced. MySQL/HTTP integration, real mobile notifications/widgets, cross-device end-to-end runs, and actual AI service credentials still need environment validation. `server/tests/http_smoke.py` and `.github/workflows/server-ci.yml` prepare the server integration gate.

The current collaboration UI shares independent snapshots; it is not a live shared workspace. The bookmark extension exports HTML on explicit action. The full UI and specialized edit forms still have follow-up work, listed in the Persian report.
