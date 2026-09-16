import '../../../core/persistence/write_status.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/drift_entity_repository.dart';
import '../domain/person.dart';

class PeopleNotifier extends StateNotifier<List<Person>> {
  PeopleNotifier({
    this.persistenceEnabled = true,
    DriftEntityRepository? repository,
  }) : _repository = repository ?? DriftEntityRepository(),
       super(const []) {
    if (persistenceEnabled) {
      _ready = WriteStatus.load(_load);
    }
  }

  static const _entityType = 'person';
  static const _uuid = Uuid();
  Future<void> _ready = Future<void>.value();
  final bool persistenceEnabled;
  final DriftEntityRepository _repository;

  Future<void> _load() async {
    try {
      await _repository.migrateLegacyList(
        migrationKey: 'v0.7.people.v1',
        entityType: _entityType,
        preferenceKeys: const ['people.v1'],
      );
      state =
          (await _repository.loadAll(_entityType)).map(Person.fromJson).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
    } catch (error) {
      WriteStatus.report(error);
    }
  }

  Future<void> _persist() async {
    if (!persistenceEnabled) return;
    await _ready;
    await _repository.replaceAll(
      _entityType,
      state.map((item) => item.toJson()),
    );
  }

  String add({
    required String name,
    String? relationship,
    String? phone,
    String? email,
    DateTime? birthDate,
    String? notes,
  }) {
    final id = _uuid.v4();
    state = [
      ...state,
      Person(
        id: id,
        name: name.trim(),
        relationship: relationship?.trim(),
        phone: phone?.trim(),
        email: email?.trim(),
        birthDate: birthDate,
        notes: notes?.trim(),
      ),
    ]..sort((a, b) => a.name.compareTo(b.name));
    WriteStatus.track(_persist());
    return id;
  }

  void delete(String id) {
    state = state.where((person) => person.id != id).toList();
    WriteStatus.track(_persist());
  }
}

final peopleProvider = StateNotifierProvider<PeopleNotifier, List<Person>>(
  (ref) => PeopleNotifier(),
);
