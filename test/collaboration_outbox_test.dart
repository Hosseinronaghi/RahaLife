import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raha_life/features/workspace/collaboration_outbox.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'offline message keeps identity across retries and is scoped to account',
    () async {
      SharedPreferences.setMockInitialValues({});
      final q = CollaborationOutbox('https://one.example', 'alice');
      final item = await q.enqueue('bob', 'hello');
      await expectLater(
        q.retry((_) async {
          throw StateError('network');
        }),
        throwsStateError,
      );
      expect((await q.read('outbox')).single['id'], item['id']);
      expect(
        await CollaborationOutbox(
          'https://two.example',
          'alice',
        ).read('outbox'),
        isEmpty,
      );
      expect(
        await CollaborationOutbox('https://one.example', 'bob').read('outbox'),
        isEmpty,
      );
      var sent = '';
      await q.retry((row) async {
        sent = row['id'] as String;
      });
      expect(sent, item['id']);
      expect(await q.read('outbox'), isEmpty);
    },
  );
}
