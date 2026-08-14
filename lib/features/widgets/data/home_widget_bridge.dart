import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class RahaWidgetDashboardData {
  const RahaWidgetDashboardData({
    required this.todayTitle,
    required this.todaySummary,
    required this.todayNextItem,
    required this.affairsTitle,
    required this.affairsSummary,
    required this.medicationTitle,
    required this.medicationSummary,
    required this.appointmentTitle,
    required this.appointmentSummary,
    required this.shoppingTitle,
    required this.shoppingSummary,
    required this.birthdayTitle,
    required this.birthdaySummary,
    required this.quickAddTitle,
    required this.quickAddLabel,
  });

  final String todayTitle;
  final String todaySummary;
  final String todayNextItem;
  final String affairsTitle;
  final String affairsSummary;
  final String medicationTitle;
  final String medicationSummary;
  final String appointmentTitle;
  final String appointmentSummary;
  final String shoppingTitle;
  final String shoppingSummary;
  final String birthdayTitle;
  final String birthdaySummary;
  final String quickAddTitle;
  final String quickAddLabel;
}

class RahaHomeWidgetBridge {
  RahaHomeWidgetBridge._();

  static const androidToday = 'RahaTodayWidget';
  static const androidAffairs = 'RahaAffairsWidget';
  static const androidMedication = 'RahaMedicationWidget';
  static const androidAppointment = 'RahaAppointmentWidget';
  static const androidShopping = 'RahaShoppingWidget';
  static const androidBirthday = 'RahaBirthdayWidget';
  static const androidQuickAdd = 'RahaQuickAddWidget';
  static const iosName = 'RahaTodayWidget';
  static const appGroupId = 'group.com.raha.rahaLife';

  static bool get _isSupportedNativePlatform => !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> configure() async {
    if (!_isSupportedNativePlatform) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await HomeWidget.setAppGroupId(appGroupId);
    }
  }

  static Future<void> requestPinAndroid(String androidName) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await HomeWidget.requestPinWidget(androidName: androidName);
  }

  static Future<void> updateDashboard(
    RahaWidgetDashboardData data, {
    bool hideSensitive = false,
  }) async {
    if (!_isSupportedNativePlatform) return;
    await configure();

    String privateValue(String value) => hideSensitive ? '••••' : value;

    final values = <String, String>{
      'today_title': data.todayTitle,
      'today_summary': data.todaySummary,
      'today_next_item': privateValue(data.todayNextItem),
      'affairs_title': data.affairsTitle,
      'affairs_summary': privateValue(data.affairsSummary),
      'medication_title': data.medicationTitle,
      'medication_summary': privateValue(data.medicationSummary),
      'appointment_title': data.appointmentTitle,
      'appointment_summary': privateValue(data.appointmentSummary),
      'shopping_title': data.shoppingTitle,
      'shopping_summary': privateValue(data.shoppingSummary),
      'birthday_title': data.birthdayTitle,
      'birthday_summary': privateValue(data.birthdaySummary),
      'quick_add_title': data.quickAddTitle,
      'quick_add_label': data.quickAddLabel,
    };
    for (final entry in values.entries) {
      await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await HomeWidget.updateWidget(iOSName: iosName);
      } catch (_) {}
      return;
    }

    for (final name in const [
      androidToday,
      androidAffairs,
      androidMedication,
      androidAppointment,
      androidShopping,
      androidBirthday,
      androidQuickAdd,
    ]) {
      try {
        await HomeWidget.updateWidget(androidName: name);
      } catch (_) {
        // A native widget target might be absent from a custom Android build.
      }
    }
  }
}
