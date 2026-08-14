import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/share_models.dart';

class SharingNotifier extends StateNotifier<List<ShareGrant>> {
  SharingNotifier({this.persistenceEnabled = true}) : super(const []) {
    if (persistenceEnabled) unawaited(_load());
  }

  static const _key = 'sharing.grants.v1';
  static const _uuid = Uuid();
  final bool persistenceEnabled;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      state = (jsonDecode(raw) as List<dynamic>)
          .map((item) => ShareGrant.fromJson(Map<String, Object?>.from(item as Map)))
          .toList(growable: false);
    } catch (_) {}
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((item) => item.toJson()).toList()));
  }

  void share({
    required String entityType,
    required String entityId,
    required Iterable<String> personIds,
    required SharePermission permission,
  }) {
    final withoutOld = state.where(
      (item) => !(item.entityType == entityType && item.entityId == entityId),
    );
    state = [
      ...withoutOld,
      for (final personId in personIds)
        ShareGrant(
          id: _uuid.v4(),
          entityType: entityType,
          entityId: entityId,
          personId: personId,
          permission: permission,
          createdAt: DateTime.now().toUtc(),
        ),
    ];
    unawaited(_persist());
  }

  void revoke(String id) {
    state = state.where((item) => item.id != id).toList(growable: false);
    unawaited(_persist());
  }
}

final sharingProvider = StateNotifierProvider<SharingNotifier, List<ShareGrant>>(
  (ref) => SharingNotifier(),
);
