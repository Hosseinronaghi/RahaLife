import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/sharing/domain/share_models.dart';

void main() {
  test('share grant keeps permission through json round-trip', () {
    final grant = ShareGrant(
      id: 'g1',
      entityType: 'shopping',
      entityId: 'list1',
      personId: 'p1',
      permission: SharePermission.check,
      createdAt: DateTime.utc(2026, 8, 10),
    );
    final restored = ShareGrant.fromJson(grant.toJson());
    expect(restored.permission, SharePermission.check);
    expect(restored.entityId, 'list1');
  });
}
