import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Durable retries are partitioned by server and account; tokens are never stored here.
class CollaborationOutbox {
  CollaborationOutbox(this.server, this.account);
  final String server, account;
  static final _tails = <String, Future<void>>{};
  Future<T> _exclusive<T>(Future<T> Function() action) {
    final next = (_tails[prefix] ?? Future<void>.value())
        .catchError((Object _) {})
        .then((_) => action());
    _tails[prefix] = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return next;
  }

  String get prefix =>
      'collab.${sha256.convert(utf8.encode('$server|$account'))}';
  Future<List<Map<String, dynamic>>> read(String suffix) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$prefix.$suffix');
    return raw == null
        ? []
        : (jsonDecode(raw) as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
  }

  Future<void> write(String suffix, List<Map<String, dynamic>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString('$prefix.$suffix', jsonEncode(rows))) {
      throw StateError('Local queue write failed');
    }
  }

  Future<Map<String, dynamic>> enqueue(String recipient, String text) =>
      _exclusive(() async {
        final item = <String, dynamic>{
          'id': const Uuid().v4(),
          'to': recipient,
          'text': text,
        };
        await write('outbox', [...await read('outbox'), item]);
        return item;
      });

  Future<void> acknowledge(String id) => _exclusive(() async {
    await write(
      'outbox',
      (await read('outbox')).where((e) => e['id'] != id).toList(),
    );
  });

  Future<void> retry(Future<void> Function(Map<String, dynamic>) send) async {
    for (final item in await read('outbox')) {
      await send(item);
      await acknowledge(item['id'] as String);
    }
  }
}
