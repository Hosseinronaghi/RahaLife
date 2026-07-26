import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AppSettings {
  const AppSettings({this.locale = const Locale('fa'), this.themeMode = ThemeMode.system});
  final Locale locale;
  final ThemeMode themeMode;

  AppSettings copyWith({Locale? locale, ThemeMode? themeMode}) =>
      AppSettings(locale: locale ?? this.locale, themeMode: themeMode ?? this.themeMode);
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings());
  void setLocale(Locale locale) => state = state.copyWith(locale: locale);
  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(),
);
