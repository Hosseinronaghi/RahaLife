import 'package:flutter/material.dart';

import '../core/settings/app_settings.dart';
import 'design_system/raha_tokens.dart';

ThemeData buildLightTheme({
  required Locale locale,
  required AccentChoice accent,
}) => _buildTheme(
  brightness: Brightness.light,
  locale: locale,
  seedColor: accent.color,
);

ThemeData buildDarkTheme({
  required Locale locale,
  required AccentChoice accent,
}) => _buildTheme(
  brightness: Brightness.dark,
  locale: locale,
  seedColor: accent.color,
);

ThemeData _buildTheme({
  required Brightness brightness,
  required Locale locale,
  required Color seedColor,
}) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
    surface: isDark ? const Color(0xFF191D1C) : const Color(0xFFF7F8F6),
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
  );

  // Always derive typography from the active Material color scheme. The old
  // implementation passed a package-owned TextTheme into Google Fonts, which
  // could keep light text colors in light mode on Android and Windows.
  final materialTextTheme = base.textTheme.apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );
  const persianFallbackFamily = 'Vazirmatn';
  final textTheme = materialTextTheme.apply(
    fontFamily: locale.languageCode == 'fa' ? persianFallbackFamily : null,
  );
  final resolvedTextTheme = textTheme.copyWith(
    displayLarge: textTheme.displayLarge?.copyWith(
      color: colorScheme.onSurface,
    ),
    displayMedium: textTheme.displayMedium?.copyWith(
      color: colorScheme.onSurface,
    ),
    displaySmall: textTheme.displaySmall?.copyWith(
      color: colorScheme.onSurface,
    ),
    headlineLarge: textTheme.headlineLarge?.copyWith(
      color: colorScheme.onSurface,
    ),
    headlineMedium: textTheme.headlineMedium?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w800,
      letterSpacing: locale.languageCode == 'fa' ? 0 : -0.8,
    ),
    headlineSmall: textTheme.headlineSmall?.copyWith(
      color: colorScheme.onSurface,
    ),
    titleLarge: textTheme.titleLarge?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: textTheme.titleMedium?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
    titleSmall: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface),
    bodyLarge: textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurface,
      height: 1.55,
    ),
    bodyMedium: textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurface,
      height: 1.5,
    ),
    bodySmall: textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
    labelLarge: textTheme.labelLarge?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
    labelMedium: textTheme.labelMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
    labelSmall: textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
  );
  final subtleBorder = colorScheme.outlineVariant.withValues(
    alpha: isDark ? 0.7 : 0.8,
  );

  return base.copyWith(
    textTheme: resolvedTextTheme,
    primaryTextTheme: resolvedTextTheme,
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    disabledColor: colorScheme.onSurface.withValues(alpha: 0.38),
    splashFactory: InkSparkle.splashFactory,
    iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
    appBarTheme: AppBarThemeData(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: colorScheme.onSurface,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: resolvedTextTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RahaRadius.card),
        side: BorderSide(color: subtleBorder),
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: colorScheme.onSurface,
      iconColor: colorScheme.onSurfaceVariant,
      subtitleTextStyle: resolvedTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    dividerTheme: DividerThemeData(color: subtleBorder, space: 1),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: colorScheme.surfaceContainerLow,
      indicatorColor: colorScheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return resolvedTextTheme.labelMedium?.copyWith(
          color: states.contains(WidgetState.selected)
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: states.contains(WidgetState.selected) ? 25 : 23,
          color: states.contains(WidgetState.selected)
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      indicatorColor: colorScheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
      unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      selectedLabelTextStyle: resolvedTextTheme.labelLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      unselectedLabelTextStyle: resolvedTextTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      groupAlignment: -0.75,
      useIndicator: true,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.7 : 0.55,
      ),
      labelStyle: resolvedTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      hintStyle: resolvedTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RahaRadius.control),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RahaRadius.control),
        borderSide: BorderSide(color: subtleBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RahaRadius.control),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: colorScheme.onPrimary,
        backgroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RahaRadius.control),
        ),
        textStyle: resolvedTextTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RahaRadius.control),
        ),
        side: BorderSide(color: subtleBorder),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RahaRadius.control),
          ),
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide(color: subtleBorder, width: 1.4),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.surfaceContainerHighest,
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(RahaRadius.pill),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 3,
      highlightElevation: 5,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primaryContainer,
      disabledColor: colorScheme.surfaceContainerHighest,
      side: BorderSide(color: subtleBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RahaRadius.control),
      ),
      labelStyle: resolvedTextTheme.labelMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
      secondaryLabelStyle: resolvedTextTheme.labelMedium?.copyWith(
        color: colorScheme.onPrimaryContainer,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurface,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.secondaryContainer
              : colorScheme.surfaceContainerLow,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: colorScheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RahaRadius.sheet),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: resolvedTextTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      contentTextStyle: resolvedTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RahaRadius.card),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: colorScheme.primaryContainer,
      headerForegroundColor: colorScheme.onPrimaryContainer,
      dayForegroundColor: WidgetStatePropertyAll(colorScheme.onSurface),
      weekdayStyle: resolvedTextTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      yearForegroundColor: WidgetStatePropertyAll(colorScheme.onSurface),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: colorScheme.surface,
      hourMinuteTextColor: colorScheme.onSurface,
      hourMinuteColor: colorScheme.surfaceContainerHighest,
      dayPeriodTextColor: colorScheme.onSurface,
      dayPeriodColor: colorScheme.surfaceContainerHighest,
      dialTextColor: colorScheme.onSurface,
      dialBackgroundColor: colorScheme.surfaceContainerHighest,
      entryModeIconColor: colorScheme.primary,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colorScheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      textStyle: resolvedTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: resolvedTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      actionTextColor: colorScheme.inversePrimary,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
