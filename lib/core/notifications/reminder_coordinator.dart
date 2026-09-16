import 'dart:collection';
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'agenda.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/widgets/data/home_widget_bridge.dart';
import 'reminder_service.dart';
import 'reminder_models.dart';

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
    final today = items
        .where(
          (e) =>
              e.at.year == DateTime.now().year &&
              e.at.month == DateTime.now().month &&
              e.at.day == DateTime.now().day,
        )
        .toList();
    String first(String type) =>
        today.where((e) => e.type == type).firstOrNull?.title ?? '—';
    await RahaHomeWidgetBridge.updateDashboard(
      RahaWidgetDashboardData(
        todayTitle: fa ? 'امروز' : 'Today',
        todaySummary: '${today.length}',
        todayNextItem: today.firstOrNull?.title ?? '—',
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
    final service = ReminderService.instance;
    await service.cancelAllManaged();
    final now = DateTime.now();
    // Respect the limited pending-notification budget on Apple devices.
    final pending = items
        .where(
          (e) =>
              !e.done &&
              e.plan.enabled &&
              e.at
                  .subtract(Duration(minutes: e.plan.minutesBefore))
                  .isAfter(now),
        )
        .take(60);
    for (final item in pending) {
      await service.schedule(
        key: item.key,
        title: item.title,
        body: item.title,
        eventDateTime: item.at,
        plan: item.plan.copyWith(repeat: ReminderRepeat.none),
        payload: 'route:${item.route}',
      );
    }
  }

  void dispose() => _timer?.cancel();
}
