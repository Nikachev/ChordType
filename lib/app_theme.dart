import 'package:flutter/material.dart';

abstract final class ChordtypeTheme {
  static const Color seedColor = Color(0xFF006D77);

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme colors = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      contrastLevel: brightness == Brightness.dark ? 0.25 : 0,
    );

    final ThemeData baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surfaceContainerLowest,
      dividerColor: colors.outlineVariant,
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: colors.primary,
        unselectedLabelColor: colors.onSurfaceVariant,
      ),
    );

    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        bodyColor: colors.onSurface,
        displayColor: colors.onSurface,
      ),
    );
  }
}
