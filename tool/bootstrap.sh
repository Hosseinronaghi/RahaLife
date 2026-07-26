#!/usr/bin/env bash
set -euo pipefail
flutter create --platforms=android,ios,windows,macos,linux .
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
