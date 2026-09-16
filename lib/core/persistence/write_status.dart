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
  static void report(Object value) =>
      _notify(() => error.value = value.toString());
  static void track(Future<void> future) {
    late Future<void> tracked;
    tracked = future
        .catchError((Object e) {
          report(e);
        })
        .whenComplete(() {
          pending.remove(tracked);
        });
    pending.add(tracked);
  }

  static Future<void> flush() async {
    while (pending.isNotEmpty) {
      await Future.wait(pending.toList());
    }
    if (error.value != null) throw StateError(error.value!);
  }
}
