import 'package:flutter/material.dart';

ThemeData buildLightTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF536D5B),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F6F1),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide.none,
        ),
      ),
    );

ThemeData buildDarkTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8DA894),
        brightness: Brightness.dark,
      ),
    );
