import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/messages/domain/message.dart';
import 'package:raha_life/features/messages/presentation/messages_controller.dart';

void main() {
  test('new messages are queued locally for sync', () {
    final notifier = MessagesNotifier(persistenceEnabled: false);
    notifier.send(personId: 'p1', body: 'Hello');
    expect(notifier.state, hasLength(1));
    expect(notifier.state.single.syncStatus, MessageSyncStatus.pending);
  });
}
