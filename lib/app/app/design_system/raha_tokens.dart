import 'package:flutter/material.dart';

abstract final class RahaSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double hero = 40;
}

abstract final class RahaRadius {
  static const double control = 16;
  static const double card = 24;
  static const double hero = 30;
  static const double sheet = 30;
  static const double pill = 999;
}

abstract final class RahaMotion {
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration emphasized = Duration(milliseconds: 360);
  static const Curve standardCurve = Curves.easeOutCubic;
}

enum RahaModuleVisual {
  affairs,
  appointment,
  shopping,
  medication,
  cycle,
  people,
  birthday,
  notes,
  projects,
  finance,
  messages,
  general,
}

Color rahaModuleAccent(RahaModuleVisual module, ColorScheme scheme) =>
    switch (module) {
      RahaModuleVisual.affairs => scheme.primary,
      RahaModuleVisual.appointment => scheme.secondary,
      RahaModuleVisual.shopping => const Color(0xFF0F9F75),
      RahaModuleVisual.medication => const Color(0xFF2578D4),
      RahaModuleVisual.cycle => const Color(0xFF9A67C7),
      RahaModuleVisual.people => const Color(0xFF3C82C4),
      RahaModuleVisual.birthday => const Color(0xFFE2853A),
      RahaModuleVisual.notes => const Color(0xFF8A6AB0),
      RahaModuleVisual.projects => const Color(0xFF4C72C8),
      RahaModuleVisual.finance => const Color(0xFF148B5B),
      RahaModuleVisual.messages => const Color(0xFF3878C7),
      RahaModuleVisual.general => scheme.primary,
    };
