import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentityService {
  DeviceIdentityService._();

  static const _storageKey = 'sync.device.v1';
  static const _uuid = Uuid();
  static String? _cached;

  static Future<String> getOrCreate() async {
    final cached = _cached;
    if (cached != null && cached.isNotEmpty) return cached;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_storageKey);
    if (id == null || id.isEmpty) {
      id = _uuid.v4();
      await prefs.setString(_storageKey, id);
    }
    _cached = id;
    return id;
  }
}
