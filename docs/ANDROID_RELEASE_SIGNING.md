# Android persistent release signing

Raha Life can only be upgraded in place reliably when future Android release APK/AAB files use the same persistent signing key. The private keystore must not be committed to this source package.

## One-time GitHub repository secrets

Create and permanently retain your own release keystore. Store its values in GitHub Actions repository secrets:

- `RAHA_ANDROID_KEYSTORE_BASE64`
- `RAHA_ANDROID_KEYSTORE_PASSWORD`
- `RAHA_ANDROID_KEY_ALIAS`
- `RAHA_ANDROID_KEY_PASSWORD`

`RAHA_ANDROID_KEYSTORE_BASE64` is the base64 representation of the binary `.jks` file. Keep the original `.jks` and its passwords in a separate secure backup. Losing or changing the production signing key can prevent future builds from updating an already installed production app.

## Workflow behavior

`.github/workflows/build-release.yml` detects whether the keystore secret exists. If present, it reconstructs a temporary `android/app/raha-release.jks`, writes temporary `android/key.properties`, and runs `tool/configure_android_release_signing.py` after Flutter generates the Android platform.

The keystore and key properties are generated only inside CI and are not included in the source ZIP.

Each Android artifact includes `SIGNING_STATUS.txt`. A build that says persistent signing is not configured should be treated as a development/test artifact, not as the permanent production update lineage.
