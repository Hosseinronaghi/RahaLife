import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_life/features/ai/data/openai_compatible_provider.dart';
import 'package:raha_life/features/ai/domain/ai_provider.dart';
import 'package:raha_life/features/home/domain/home_entry.dart';
import 'package:raha_life/features/home/domain/birthday_occurrence.dart';
import 'package:raha_life/features/medication/domain/medication_dose.dart';
import 'package:raha_life/core/sync/sync_scope.dart';

class _RedirectAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '',
      302,
      headers: {
        'location': ['https://other.example/steal'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'AI refuses unsafe credential destinations before any request',
    () async {
      final adapter = _RedirectAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      for (final url in [
        'http://example.com',
        'https://u:p@example.com',
        'https://example.com?key=a',
        'https://example.com#fragment',
      ]) {
        final client = OpenAiCompatibleProvider(
          apiKey: 'test-only',
          model: 'model',
          baseUrl: url,
          dio: dio,
        );
        await expectLater(
          client.generate(const AiRequest(prompt: 'test')),
          throwsArgumentError,
        );
      }
      expect(adapter.requests, isEmpty);
    },
  );
  test('AI rejects redirect rather than accepting its response', () async {
    final adapter = _RedirectAdapter();
    final client = OpenAiCompatibleProvider(
      apiKey: 'test-only',
      model: 'model',
      dio: Dio()..httpClientAdapter = adapter,
    );
    await expectLater(
      client.generate(const AiRequest(prompt: 'test')),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.followRedirects, isFalse);
  });
  test('dose history round trip preserves explicit missed status', () {
    final at = DateTime.utc(2026, 9, 20, 8);
    final dose = MedicationDose(
      id: MedicationDose.occurrenceId('plan', at),
      planId: 'plan',
      scheduledAt: at,
      outcome: DoseOutcome.notTaken,
      recordedAt: at,
      reason: 'User reported',
    );
    final restored = MedicationDose.fromJson(dose.toJson());
    expect(restored.outcome, DoseOutcome.notTaken);
    expect(restored.takenAt, isNull);
    expect(restored.id, MedicationDose.occurrenceId('plan', at.toLocal()));
    expect(syncTypes({'modules': 'health'}), contains('medication_dose'));
    expect(
      syncTypes({'modules': defaultSyncModules.join(',')}),
      isNot(contains('medication_dose')),
    );
  });
  test('birthday groups cross year boundary', () {
    HomeEntry birthday(DateTime date) => HomeEntry(
      id: 'b',
      type: HomeEntryType.birthday,
      title: 'Name',
      dateTime: date,
    );
    final now = DateTime(2026, 12, 31);
    expect(birthdayGroup(birthday(DateTime(1990, 12, 31)), now), 0);
    expect(birthdayGroup(birthday(DateTime(1990, 1, 1)), now), 1);
    expect(birthdayGroup(birthday(DateTime(1990, 12, 30)), now), 3);
  });
  test('call metadata survives toggle and JSON restore', () {
    final call = HomeEntry(
      id: 'call',
      type: HomeEntryType.affair,
      title: 'Call',
      dateTime: DateTime(2026),
      subtype: 'call',
      phone: '+123456789',
      personId: 'person',
    );
    final restored = HomeEntry.fromJson(
      call.copyWith(completed: true).toJson(),
    );
    expect(restored.phone, call.phone);
    expect(restored.personId, 'person');
    expect(restored.completed, true);
  });
}
