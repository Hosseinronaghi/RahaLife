import 'dart:collection';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';

import 'agenda.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/widgets/data/home_widget_bridge.dart';
import 'reminder_service.dart';
import 'reminder_models.dart';

String publicReminderTitle(AgendaItem item, {required bool fa}) =>
    switch (item.type) {
      'medication' || 'cycle' || 'cycle_conflict' =>
        fa ? 'یادآوری رها' : 'Raha reminder',
      _ => item.title,
    };

class ReminderCoordinator {
  Timer? _timer;
  Future<void> _tail = Future<void>.value();
  void update(List<AgendaItem> items) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 700), () {
      _tail = _tail
          .catchError((Object _) {})
          .then((_) => _reconcile(items))
          .catchError((Object e) {
            ReminderService.instance.lastError.value = e.toString();
          });
    });
  }

  Future<void> _reconcile(List<AgendaItem> items) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final fa = (prefs.getString('settings.locale') ?? 'fa') == 'fa';
    final service = ReminderService.instance;
    await service.initialize();
    await service.refreshTimezone();
    final now = DateTime.now();
    final due =
        items
            .where(
              (e) => !e.done && e.plan.enabled && _fireTime(e).isAfter(now),
            )
            .toList()
          ..sort((a, b) => _fireTime(a).compareTo(_fireTime(b)));
    final requests = <String, String>{
      for (final item in due.take(60))
        item.key: sha256
            .convert(
              utf8.encode(
                jsonEncode([
                  _fireTime(item).toUtc().toIso8601String(),
                  service.schedulingTimezone,
                  publicReminderTitle(item, fa: fa),
                  item.route,
                  item.plan.kind.name,
                ]),
              ),
            )
            .toString(),
    };
    const key = 'reminders.managed_schedule.v1';
    final raw = prefs.getString(key);
    final managed = raw == null
        ? <String, String?>{}
        : Map<String, String?>.from(jsonDecode(raw) as Map);
    final existingIds = await service.pendingIds();
    final wantedItems = {for (final item in due.take(60)) item.key: item};
    await reconcileReminderSchedules(
      managed: managed,
      wanted: requests,
      isPending: (key) => existingIds.contains(service.notificationId(key)),
      save: (state) async {
        if (!await prefs.setString(key, jsonEncode(state))) {
          throw StateError('Unable to persist reminder scheduling state.');
        }
      },
      schedule: (key) {
        final item = wantedItems[key]!;
        return service.schedule(
          key: key,
          title: publicReminderTitle(item, fa: fa),
          body: publicReminderTitle(item, fa: fa),
          eventDateTime: item.at,
          plan: item.plan.copyWith(repeat: ReminderRepeat.none),
          payload: 'route:${item.route}',
        );
      },
      cancel: service.cancelManaged,
    );
    try {
      await _updateWidget(prefs, items);
    } catch (error) {
      debugPrint('Home widget update failed: $error');
    }
  }

  DateTime _fireTime(AgendaItem item) =>
      item.at.subtract(Duration(minutes: item.plan.minutesBefore));

  Future<void> _updateWidget(
    SharedPreferences prefs,
    List<AgendaItem> items,
  ) async {
    final fa = (prefs.getString('settings.locale') ?? 'fa') == 'fa';
    final today = items
        .where(
          (e) =>
              e.at.year == DateTime.now().year &&
              e.at.month == DateTime.now().month &&
              e.at.day == DateTime.now().day,
        )
        .toList();
    String first(String type) =>
          today.where((e) => e.type == type).map(
          (item) => publicReminderTitle(item, fa: fa),
        ).firstOrNull ?? '—';
    await RahaHomeWidgetBridge.updateDashboard(
      RahaWidgetDashboardData(
        todayTitle: fa ? 'امروز' : 'Today',
        todaySummary: '${today.length}',
        todayNextItem: today.isEmpty
            ? '—'
            : publicReminderTitle(today.first, fa: fa),
        affairsTitle: fa ? 'کارها' : 'Tasks',
        affairsSummary: first('affair'),
        medicationTitle: fa ? 'دارو' : 'Medication',
        medicationSummary: first('medication'),
        appointmentTitle: fa ? 'قرارها' : 'Appointments',
        appointmentSummary: first('appointment'),
        shoppingTitle: fa ? 'خرید' : 'Shopping',
        shoppingSummary: first('shopping_list'),
        birthdayTitle: fa ? 'تولد' : 'Birthday',
        birthdaySummary: first('birthday'),
        quickAddTitle: fa ? 'ثبت سریع' : 'Quick add',
        quickAddLabel: fa ? 'افزودن' : 'Add',
      ),
      hideSensitive: prefs.getBool('widgets.hideSensitive.v1') ?? false,
    );
  }

  void dispose() => _timer?.cancel();
}

// Only managed IDs are touched. An intent is persisted before a new OS write;
// after a crash, a null signature causes a safe retry using the same ID.
Future<void> reconcileReminderSchedules({
  required Map<String, String?> managed,
  required Map<String, String> wanted,
  required bool Function(String) isPending,
  required Future<void> Function(Map<String, String?>) save,
  required Future<bool> Function(String) schedule,
  required Future<void> Function(String) cancel,
}) async {
  var failed = false;
  for (final entry in wanted.entries) {
    if (managed[entry.key] == entry.value && isPending(entry.key)) continue;
    managed[entry.key] = null;
    await save(managed);
    if (!await schedule(entry.key)) {
      failed = true;
      continue;
    }
    managed[entry.key] = entry.value;
    await save(managed);
  }
  if (failed) return;
  for (final key
      in managed.keys.where((key) => !wanted.containsKey(key)).toList()) {
    await cancel(key);
    managed.remove(key);
    await save(managed);
  }
}
