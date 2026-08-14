import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/message.dart';

class MessagesNotifier extends StateNotifier<List<LocalMessage>> {
  MessagesNotifier({this.persistenceEnabled = true}) : super(const []) {
    if (persistenceEnabled) unawaited(_load());
  }

  static const _key = 'messages.local.v1';
  static const _uuid = Uuid();
  final bool persistenceEnabled;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      state = (jsonDecode(raw) as List<dynamic>)
          .map((item) => LocalMessage.fromJson(Map<String, Object?>.from(item as Map)))
          .toList(growable: false)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (_) {}
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((item) => item.toJson()).toList()));
  }

  void send({
    required String personId,
    required String body,
    String? entityType,
    String? entityId,
    String? attachmentName,
    String? attachmentPath,
  }) {
    if (body.trim().isEmpty && entityId == null && attachmentName == null) return;
    state = [
      ...state,
      LocalMessage(
        id: _uuid.v4(),
        personId: personId,
        body: body.trim(),
        createdAt: DateTime.now().toUtc(),
        sharedEntityType: entityType,
        sharedEntityId: entityId,
        attachmentName: attachmentName,
        attachmentPath: attachmentPath,
      ),
    ];
    unawaited(_persist());
  }
}

final messagesProvider = StateNotifierProvider<MessagesNotifier, List<LocalMessage>>(
  (ref) => MessagesNotifier(),
);
