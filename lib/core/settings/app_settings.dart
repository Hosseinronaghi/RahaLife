import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/domain/home_entry.dart';

enum AccentChoice { emerald, blue, purple, orange }

extension AccentChoiceColor on AccentChoice {
  Color get color => switch (this) {
        AccentChoice.emerald => const Color(0xFF22C55E),
        AccentChoice.blue => const Color(0xFF3B82F6),
        AccentChoice.purple => const Color(0xFF8B5CF6),
        AccentChoice.orange => const Color(0xFFF97316),
      };
}

@immutable
class AppSettings {
  const AppSettings({
    this.locale = const Locale('fa'),
    this.themeMode = ThemeMode.system,
    this.accentChoice = AccentChoice.emerald,
    this.textScale = 1,
    this.hiddenHomeSections = const {},
  });

  final Locale locale;
  final ThemeMode themeMode;
  final AccentChoice accentChoice;
  final double textScale;
  final Set<HomeEntryType> hiddenHomeSections;

  AppSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    AccentChoice? accentChoice,
    double? textScale,
    Set<HomeEntryType>? hiddenHomeSections,
  }) =>
      AppSettings(
        locale: locale ?? this.locale,
        themeMode: themeMode ?? this.themeMode,
        accentChoice: accentChoice ?? this.accentChoice,
        textScale: textScale ?? this.textScale,
        hiddenHomeSections: hiddenHomeSections ?? this.hiddenHomeSections,
      );
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    unawaited(_load());
  }

  static const _localeKey = 'settings.locale';
  static const _themeKey = 'settings.theme';
  static const _accentKey = 'settings.accent';
  static const _textScaleKey = 'settings.textScale';
  static const _hiddenSectionsKey = 'settings.hiddenSections';

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString(_localeKey) ?? 'fa';
    final themeIndex = preferences.getInt(_themeKey) ?? ThemeMode.system.index;
    final accentIndex =
        preferences.getInt(_accentKey) ?? AccentChoice.emerald.index;
    final hiddenNames = preferences.getStringList(_hiddenSectionsKey) ?? const [];
    final safeThemeIndex = themeIndex < 0
        ? 0
        : themeIndex >= ThemeMode.values.length
            ? ThemeMode.values.length - 1
            : themeIndex;
    final safeAccentIndex = accentIndex < 0
        ? 0
        : accentIndex >= AccentChoice.values.length
            ? AccentChoice.values.length - 1
            : accentIndex;
    state = AppSettings(
      locale: Locale(languageCode),
      themeMode: ThemeMode.values[safeThemeIndex],
      accentChoice: AccentChoice.values[safeAccentIndex],
      textScale: preferences.getDouble(_textScaleKey) ?? 1,
      hiddenHomeSections: HomeEntryType.values
          .where((type) => hiddenNames.contains(type.name))
          .toSet(),
    );
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localeKey, locale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_themeKey, mode.index);
  }

  Future<void> setAccent(AccentChoice choice) async {
    state = state.copyWith(accentChoice: choice);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_accentKey, choice.index);
  }

  Future<void> setTextScale(double scale) async {
    state = state.copyWith(textScale: scale);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_textScaleKey, scale);
  }

  Future<void> setSectionVisible(HomeEntryType type, bool visible) async {
    final hidden = {...state.hiddenHomeSections};
    if (visible) {
      hidden.remove(type);
    } else {
      hidden.add(type);
    }
    state = state.copyWith(hiddenHomeSections: hidden);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _hiddenSectionsKey,
      hidden.map((item) => item.name).toList(growable: false),
    );
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(),
);
