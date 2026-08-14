#!/usr/bin/env bash
set -euo pipefail
flutter create --platforms=android,ios,windows,macos,linux --org com.raha --project-name raha_life .
rm -f test/widget_test.dart
python3 tool/configure_apple_platforms.py
flutter clean
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
