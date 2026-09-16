import 'safe_upgrade_platform_stub.dart'
    if (dart.library.io) 'safe_upgrade_platform_native.dart'
    as implementation;

Future<void> createNativeDatabaseSafetyCopy() =>
    implementation.createNativeDatabaseSafetyCopy();
