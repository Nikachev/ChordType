import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chordtype/main.dart';

import 'test_support.dart';

void main() {
  testWidgets('theme toggle persists and restores dark mode', (
    WidgetTester tester,
  ) async {
    configureDesktopView(tester);
    final MemoryAppStorage storage = MemoryAppStorage();

    await tester.pumpWidget(ChordtypeApp(storage: storage));
    await tester.pumpAndSettle();

    expect(_materialApp(tester).themeMode, ThemeMode.light);
    expect(_brightness(tester), Brightness.light);

    await tester.tap(find.byTooltip('Use dark theme'));
    await tester.pumpAndSettle();

    expect(_materialApp(tester).themeMode, ThemeMode.dark);
    expect(_brightness(tester), Brightness.dark);
    expect(find.byTooltip('Use light theme'), findsOneWidget);
    expect(
      (jsonDecode(storage[testStorageKey]!)
          as Map<String, dynamic>)['darkMode'],
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(ChordtypeApp(storage: storage));
    await tester.pumpAndSettle();

    expect(_materialApp(tester).themeMode, ThemeMode.dark);
    expect(_brightness(tester), Brightness.dark);
  });
}

MaterialApp _materialApp(WidgetTester tester) {
  return tester.widget<MaterialApp>(find.byType(MaterialApp));
}

Brightness _brightness(WidgetTester tester) {
  final BuildContext context = tester.element(find.byType(Scaffold));
  return Theme.of(context).brightness;
}
