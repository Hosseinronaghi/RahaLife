import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_models.dart';

class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  final ValueNotifier<String?> selectedPayload = ValueNotifier<String?>(null);

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz.initializeTimeZones();
    try {
      final deviceTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTimezone.identifier));
    } catch (_) {
      // The timezone package keeps UTC as a safe fallback if the OS lookup fails.
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const windows = WindowsInitializationSettings(
      appName: 'Raha Life',
      appUserModelId: 'com.raha.life',
      guid: '6f6a1122-2e30-4db8-a5d2-41f8b571e88b',
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      windows: windows,
    );
    try {
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            selectedPayload.value = payload;
          }
        },
      );
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      final launchPayload = launchDetails?.notificationResponse?.payload;
      if ((launchDetails?.didNotificationLaunchApp ?? false) &&
          launchPayload != null &&
          launchPayload.isNotEmpty) {
        selectedPayload.value = launchPayload;
      }
    } catch (error, stackTrace) {
      debugPrint('Reminder initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _initialized = true;
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await initialize();
    var granted = true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
      try {
        await android.requestExactAlarmsPermission();
        await android.requestFullScreenIntentPermission();
      } catch (_) {
        // Exact/full-screen alarm permissions are unavailable on some devices.
      }
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      granted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final mac = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (mac != null) {
      granted = await mac.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return granted;
  }

  Future<void> schedule({
    required String key,
    required String title,
    required String body,
    required DateTime eventDateTime,
    required ReminderPlan plan,
    String? payload,
  }) async {
    if (!plan.enabled || kIsWeb) return;
    await initialize();
    final scheduledAt = eventDateTime.subtract(
      Duration(minutes: plan.minutesBefore),
    );
    if (!scheduledAt.isAfter(DateTime.now())) return;

    final isAlarm = plan.kind == ReminderKind.alarm;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        isAlarm ? 'raha_alarm' : 'raha_reminders',
        isAlarm ? 'Raha Life Alarms' : 'Raha Life Reminders',
        channelDescription: isAlarm
            ? 'Prominent alarms for time-sensitive Raha Life items.'
            : 'Gentle reminders for Raha Life items.',
        importance: isAlarm ? Importance.max : Importance.high,
        priority: isAlarm ? Priority.max : Priority.high,
        category: isAlarm ? AndroidNotificationCategory.alarm : null,
        fullScreenIntent: isAlarm,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel:
            isAlarm ? InterruptionLevel.timeSensitive : InterruptionLevel.active,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel:
            isAlarm ? InterruptionLevel.timeSensitive : InterruptionLevel.active,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        notificationId(key),
        title,
        body,
        tz.TZDateTime.local(
          scheduledAt.year,
          scheduledAt.month,
          scheduledAt.day,
          scheduledAt.hour,
          scheduledAt.minute,
        ),
        details,
        androidScheduleMode: isAlarm
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: _components(plan.repeat),
      );
    } catch (error, stackTrace) {
      debugPrint('Reminder scheduling failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> cancel(String key) async {
    if (kIsWeb) return;
    await initialize();
    try {
      await _plugin.cancel(notificationId(key));
    } catch (error) {
      debugPrint('Reminder cancellation failed: $error');
    }
  }

  Future<void> showTest({
    required String title,
    required String body,
    bool alarm = false,
  }) async {
    if (kIsWeb) return;
    await initialize();
    try {
      await _plugin.show(
        990001,
        title,
        body,
        NotificationDetails(
        android: AndroidNotificationDetails(
          alarm ? 'raha_alarm' : 'raha_reminders',
          alarm ? 'Raha Life Alarms' : 'Raha Life Reminders',
          importance: alarm ? Importance.max : Importance.high,
          priority: alarm ? Priority.max : Priority.high,
          fullScreenIntent: alarm,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (error) {
      debugPrint('Test notification failed: $error');
    }
  }

  DateTimeComponents? _components(ReminderRepeat repeat) => switch (repeat) {
        ReminderRepeat.none => null,
        ReminderRepeat.daily => DateTimeComponents.time,
        ReminderRepeat.weekly => DateTimeComponents.dayOfWeekAndTime,
        ReminderRepeat.monthly => DateTimeComponents.dayOfMonthAndTime,
        ReminderRepeat.yearly => DateTimeComponents.dateAndTime,
      };

  String? consumeSelectedPayload() {
    final payload = selectedPayload.value;
    selectedPayload.value = null;
    return payload;
  }

  @visibleForTesting
  int notificationId(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
