#!/usr/bin/env bash
set -euo pipefail
umask 077
[[ "${RAHA_PLATFORM:-}" == ios || "${RAHA_PLATFORM:-}" == macos ]]
[[ "${RAHA_APPLE_TEAM_ID:-}" =~ ^[A-Z0-9]{10}$ ]] || { echo 'Set the Apple Developer team ID.' >&2; exit 1; }

sign_dir="$(mktemp -d "$RUNNER_TEMP/raha-signing.XXXXXX")"
keychain="$sign_dir/release.keychain-db"
installed_profile=""
cleanup() {
  if [[ -n "$installed_profile" ]]; then rm -f "$installed_profile"; fi
  security delete-keychain "$keychain" >/dev/null 2>&1 || true
  rm -rf "$sign_dir"
}
trap cleanup EXIT
mkdir -p release/signed

if [[ "$RAHA_PLATFORM" == ios ]]; then
  identity_type="Apple Distribution"
  certificate="${RAHA_IOS_P12:?Configure the iOS distribution certificate in apple-release}"
  password="${RAHA_IOS_P12_PASSWORD:-}"
else
  identity_type="Developer ID Application"
  certificate="${RAHA_MAC_P12:?Configure the Developer ID certificate in apple-release}"
  password="${RAHA_MAC_P12_PASSWORD:-}"
fi
printf '%s' "$certificate" | base64 -D > "$sign_dir/certificate.p12"
keychain_password="$(openssl rand -hex 32)"
security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 7200 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
security list-keychains -d user -s "$keychain"
security import "$sign_dir/certificate.p12" -k "$keychain" -P "$password" -T /usr/bin/codesign >/dev/null
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$keychain_password" "$keychain" >/dev/null
identity="$(security find-identity -v -p codesigning "$keychain" |
  awk -v kind="$identity_type:" -v team="($RAHA_APPLE_TEAM_ID)" '
    index($0, kind) && index($0, team) { print $2 }
  ')"
[[ "$identity" =~ ^[A-Fa-f0-9]{40}$ ]] || { echo "Expected one valid $identity_type identity." >&2; exit 1; }

if [[ "$RAHA_PLATFORM" == ios ]]; then
  printf '%s' "${RAHA_IOS_PROFILE:?Configure an Ad Hoc iOS profile for the registered test devices}" |
    base64 -D > "$sign_dir/ios.mobileprovision"
  security cms -D -i "$sign_dir/ios.mobileprovision" > "$sign_dir/profile.plist"
  metadata="$(python3 tool/configure_ios_release_signing.py "$sign_dir/profile.plist" "$sign_dir/export.plist")"
  [[ "$metadata" =~ ^[A-Fa-f0-9-]{36}$ ]]
  profile_parent="$HOME/Library/MobileDevice/Provisioning Profiles"
  mkdir -p "$profile_parent"
  installed_profile="$profile_parent/$metadata.mobileprovision"
  cp "$sign_dir/ios.mobileprovision" "$installed_profile"
  flutter build ipa --release --export-options-plist="$sign_dir/export.plist" --dart-define-from-file=build/oauth-ios.json
  products=(build/ios/ipa/*.ipa)
  [[ ${#products[@]} -eq 1 && -f "${products[0]}" ]]
  ditto -x -k "${products[0]}" "$sign_dir/ipa"
  app=("$sign_dir"/ipa/Payload/*.app)
  [[ ${#app[@]} -eq 1 && -d "${app[0]}" && -f "${app[0]}/embedded.mobileprovision" ]]
  codesign --verify --deep --strict "${app[0]}"
  cp "${products[0]}" release/signed/Raha-Life-iOS-ad-hoc.ipa
else
  apps=(build/macos/Build/Products/Release/*.app)
  [[ ${#apps[@]} -eq 1 && -d "${apps[0]}" ]]
  app="${apps[0]}"
  entitlement="macos/Runner/Release.entitlements"
  [[ -f "$entitlement" ]]
  if [[ -n "${RAHA_ICLOUD_CONTAINER:-}" ]]; then
    printf '%s' "${RAHA_MAC_PROFILE:?A matching Developer ID iCloud provisioning profile is required}" |
      base64 -D > "$app/Contents/embedded.provisionprofile"
  fi
  # Frameworks are signed from the inside out, followed by the app itself.
  framework_dir="$app/Contents/Frameworks"
  if [[ -d "$framework_dir" ]]; then
    while IFS= read -r -d '' nested; do
      codesign --force --timestamp --options runtime --sign "$identity" "$nested"
    done < <(find "$framework_dir" -depth \( -type d -name '*.framework' -o -type f -name '*.dylib' \) -print0)
  fi
  codesign --force --timestamp --options runtime --sign "$identity" --entitlements "$entitlement" "$app"
  codesign --verify --deep --strict "$app"
  stage="$sign_dir/dmg"
  mkdir -p "$stage"
  ditto "$app" "$stage/Raha Life.app"
  ln -s /Applications "$stage/Applications"
  dmg="release/signed/Raha-Life-macOS.dmg"
  hdiutil create -volname 'Raha Life' -srcfolder "$stage" -format UDZO "$dmg"
  codesign --timestamp --sign "$identity" "$dmg"
  printf '%s' "${RAHA_NOTARY_API_KEY:?Configure a base64 App Store Connect API private key}" |
    base64 -D > "$sign_dir/notary.p8"
  xcrun notarytool submit "$dmg" --wait --timeout 30m --key "$sign_dir/notary.p8" \
    --key-id "${RAHA_NOTARY_KEY_ID:?Configure the notarization key ID}" \
    --issuer "${RAHA_NOTARY_ISSUER:?Configure the notarization issuer}"
  xcrun stapler staple "$dmg"
  xcrun stapler validate "$dmg"
fi

(cd release/signed && shasum -a 256 ./* > SHA256SUMS.txt)
