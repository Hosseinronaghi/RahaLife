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
    String? id,
    required String name,
    String? relationship,
    String? phone,
    String? email,
    DateTime? birthDate,
    String birthCalendar = 'gregorian',
    String? notes,
  }) {
    final personId = id ?? _uuid.v4();
    if (name.trim().isEmpty) throw ArgumentError('Name is required');
    state = [
      ...state.where((p) => p.id != personId),
      Person(
        id: personId,
        name: name.trim(),
        relationship: relationship?.trim(),
        phone: phone?.trim(),
        email: email?.trim(),
        birthDate: birthDate,
        birthCalendar: birthCalendar,
        notes: notes?.trim(),
      ),
    ]..sort((a, b) => a.name.compareTo(b.name));
    WriteStatus.track(_persist());
    return personId;
  }

  void delete(String id) {
    state = state.where((person) => person.id != id).toList();
    WriteStatus.track(_persist());
  }
}

final peopleProvider = StateNotifierProvider<PeopleNotifier, List<Person>>(
  (ref) => PeopleNotifier(),
);
