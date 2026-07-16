import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chordtype/main.dart';

import 'test_support.dart';

void main() {
  testWidgets('English course shows English interface labels', (
    WidgetTester tester,
  ) async {
    configureDesktopView(tester);

    await tester.pumpWidget(ChordtypeApp(storage: MemoryAppStorage()));
    await tester.pumpAndSettle();

    expect(find.text('English: course'), findsOneWidget);
    expect(find.text('Layout'), findsAtLeastNWidgets(1));
    expect(find.text('Base'), findsOneWidget);
    expect(find.text('Numbers & symbols'), findsOneWidget);
    expect(find.text('Symbols'), findsNothing);
    expect(find.text('Numbers'), findsNothing);
    expect(find.text('Output'), findsOneWidget);
    expect(find.text('Chord'), findsOneWidget);
    expect(find.text('Left'), findsOneWidget);
    expect(find.text('Right'), findsOneWidget);
    expect(find.text('Ready'), findsAtLeastNWidgets(1));
    expect(find.textContaining('accuracy'), findsOneWidget);
    expect(find.textContaining('errors'), findsOneWidget);
    expect(find.byTooltip('Hide chord hint'), findsOneWidget);
    expect(find.text('Русский: курс'), findsNothing);
  });

  testWidgets('switching to Russian localizes the interface', (
    WidgetTester tester,
  ) async {
    configureDesktopView(tester);

    await tester.pumpWidget(ChordtypeApp(storage: MemoryAppStorage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RU').first);
    await tester.pumpAndSettle();

    expect(find.text('Русский: курс'), findsOneWidget);
    expect(find.text('Раскладка'), findsAtLeastNWidgets(1));
    expect(find.text('База'), findsOneWidget);
    expect(find.text('Цифры и символы'), findsOneWidget);
    expect(find.text('Символы'), findsNothing);
    expect(find.text('Цифры'), findsNothing);
    expect(find.text('Результат'), findsOneWidget);
    expect(find.text('Аккорд'), findsOneWidget);
    expect(find.text('Левая'), findsOneWidget);
    expect(find.text('Правая'), findsOneWidget);
    expect(find.text('Готово'), findsAtLeastNWidgets(1));
    expect(find.textContaining('точность'), findsOneWidget);
    expect(find.textContaining('ошибки'), findsOneWidget);
    expect(find.byTooltip('Скрыть подсказку аккорда'), findsOneWidget);
    for (final String role in <String>[
      'мизинец',
      'безымянный',
      'средний',
      'указательный',
    ]) {
      expect(find.text(role), findsOneWidget);
    }
    expect(find.byIcon(Icons.pan_tool_alt_rounded), findsNothing);
    expect(find.text('English: course'), findsNothing);
  });
}
