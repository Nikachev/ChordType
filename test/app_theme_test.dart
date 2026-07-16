import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chordtype/app_theme.dart';

void main() {
  for (final (ThemeData theme, Brightness brightness)
      in <(ThemeData, Brightness)>[
    (ChordtypeTheme.light, Brightness.light),
    (ChordtypeTheme.dark, Brightness.dark),
  ]) {
    test('$brightness theme uses the shared Material color contract', () {
      expect(theme.brightness, brightness);
      expect(theme.useMaterial3, isTrue);
      expect(theme.textTheme.bodyMedium?.color, theme.colorScheme.onSurface);
      expect(theme.textTheme.headlineSmall?.color, theme.colorScheme.onSurface);
      expect(
        theme.scaffoldBackgroundColor,
        theme.colorScheme.surfaceContainerLowest,
      );
      expect(theme.dividerColor, theme.colorScheme.outlineVariant);
    });
  }

  test('keeps the documented seed color stable', () {
    expect(ChordtypeTheme.seedColor, const Color(0xFF006D77));
  });
}
