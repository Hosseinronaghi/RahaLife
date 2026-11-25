import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

class WriteStatus {
  static int _loading = 0;
  static void _notify(VoidCallback action) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => action());
    } else {
      action();
    }
  }

  static final loading = ValueNotifier<int>(0);
  static Future<void> load(Future<void> Function() action) async {
    _loading++;
    _notify(() => loading.value = _loading);
    try {
      await action();
    } finally {
      _loading--;
      _notify(() => loading.value = _loading);
    }
  }

  static final error = ValueNotifier<String?>(null);
  static final pending = <Future<void>>{};
  static String? _loadError;
  static int _sequence = 0;
  static final _failed =
      <
        Object,
        ({int sequence, Future<void> Function()? retry, String message})
      >{};

  /// A failed load requires reloading; it must not be confused with a retryable save.
  static void report(Object value) {
    _loadError = value.toString();
    _publishError();
  }

  static void _publishError() {
    final message =
        _loadError ?? (_failed.isEmpty ? null : _failed.values.last.message);
    if (error.value == message) {
      return;
    }
    _notify(() => error.value = message);
  }

  static void track(Future<void> future, {Future<void> Function()? retry}) {
    final key = retry ?? Object();
    final sequence = ++_sequence;
    late Future<void> tracked;
    tracked = future
        .then<void>(
          (_) {
            final failure = _failed[key];
            if (failure != null && failure.sequence <= sequence) {
              _failed.remove(key);
            }
            _publishError();
          },
          onError: (Object e, StackTrace stack) {
            final failure = _failed[key];
            if (failure == null || failure.sequence <= sequence) {
              _failed[key] = (
                sequence: sequence,
                retry: retry,
                message: e.toString(),
              );
            }
            _publishError();
          },
        )
        .whenComplete(() => pending.remove(tracked));
    pending.add(tracked);
  }

  static Future<void> retryFailed() async {
    while (pending.isNotEmpty) {
      await Future.wait(pending.toList());
    }
    for (final failure in _failed.values.toList()) {
      final retry = failure.retry;
      if (retry != null) track(Future<void>.sync(retry), retry: retry);
    }
    while (pending.isNotEmpty) {
      await Future.wait(pending.toList());
    }
  }

  /// Called only when explicitly discarding unsaved view state and loading stored data.
  static void resetForReload() {
    _loadError = null;
    _failed.clear();
    _publishError();
  }

  static Future<void> flush() async {
    await retryFailed();
    final failure =
        _loadError ?? (_failed.isEmpty ? null : _failed.values.last.message);
    if (failure != null) throw StateError(failure);
  }
}
