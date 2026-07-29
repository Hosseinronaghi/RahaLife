import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/domain/home_entry.dart';
import 'app_module.dart';

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
    this.moduleOrder = defaultAppModuleOrder,
    this.hiddenModules = const {},
  });

  final Locale locale;
  final ThemeMode themeMode;
  final AccentChoice accentChoice;
  final double textScale;
  final Set<HomeEntryType> hiddenHomeSections;
  final List<AppModule> moduleOrder;
  final Set<AppModule> hiddenModules;

  AppSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    AccentChoice? accentChoice,
    double? textScale,
    Set<HomeEntryType>? hiddenHomeSections,
    List<AppModule>? moduleOrder,
    Set<AppModule>? hiddenModules,
  }) =>
      AppSettings(
        locale: locale ?? this.locale,
        themeMode: themeMode ?? this.themeMode,
        accentChoice: accentChoice ?? this.accentChoice,
        textScale: textScale ?? this.textScale,
        hiddenHomeSections: hiddenHomeSections ?? this.hiddenHomeSections,
        moduleOrder: moduleOrder ?? this.moduleOrder,
        hiddenModules: hiddenModules ?? this.hiddenModules,
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
  static const _moduleOrderKey = 'settings.moduleOrder.v1';
  static const _hiddenModulesKey = 'settings.hiddenModules.v1';

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString(_localeKey) ?? 'fa';
    final themeIndex = preferences.getInt(_themeKey) ?? ThemeMode.system.index;
    final accentIndex =
        preferences.getInt(_accentKey) ?? AccentChoice.emerald.index;
    final hiddenNames = preferences.getStringList(_hiddenSectionsKey) ?? const [];
    final savedOrder = preferences.getStringList(_moduleOrderKey) ?? const [];
    final hiddenModuleNames =
        preferences.getStringList(_hiddenModulesKey) ?? const [];
    final safeThemeIndex = themeIndex.clamp(0, ThemeMode.values.length - 1).toInt();
    final safeAccentIndex = accentIndex.clamp(0, AccentChoice.values.length - 1).toInt();

    final restoredOrder = <AppModule>[];
    for (final name in savedOrder) {
      for (final module in AppModule.values) {
        if (module.name == name && !restoredOrder.contains(module)) {
          restoredOrder.add(module);
        }
      }
    }
    for (final module in defaultAppModuleOrder) {
      if (!restoredOrder.contains(module)) restoredOrder.add(module);
    }

    state = AppSettings(
      locale: Locale(languageCode),
      themeMode: ThemeMode.values[safeThemeIndex],
      accentChoice: AccentChoice.values[safeAccentIndex],
      textScale: preferences.getDouble(_textScaleKey) ?? 1,
      hiddenHomeSections: HomeEntryType.values
          .where((type) => hiddenNames.contains(type.name))
          .toSet(),
      moduleOrder: restoredOrder,
      hiddenModules: AppModule.values
          .where((module) => hiddenModuleNames.contains(module.name))
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

  Future<void> reorderModules(int oldIndex, int newIndex) async {
    final modules = [...state.moduleOrder];
    // ReorderableListView.onReorderItem already adjusts newIndex after removal.
    final item = modules.removeAt(oldIndex);
    modules.insert(newIndex, item);
    state = state.copyWith(moduleOrder: modules);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _moduleOrderKey,
      modules.map((item) => item.name).toList(growable: false),
    );
  }

  Future<void> setModuleVisible(AppModule module, bool visible) async {
    final hidden = {...state.hiddenModules};
    if (visible) {
      hidden.remove(module);
    } else {
      hidden.add(module);
    }
    state = state.copyWith(hiddenModules: hidden);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _hiddenModulesKey,
      hidden.map((item) => item.name).toList(growable: false),
    );
  }

  Future<void> resetModuleLayout() async {
    state = state.copyWith(
      moduleOrder: defaultAppModuleOrder,
      hiddenModules: <AppModule>{},
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_moduleOrderKey);
    await preferences.remove(_hiddenModulesKey);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(),
);
