import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chordtype/chord_data.dart';
import 'package:chordtype/course_data.dart';
import 'package:chordtype/main.dart';

import 'test_support.dart';

void main() {
  testWidgets('restores every persisted UI preference', (
    WidgetTester tester,
  ) async {
    configureDesktopView(tester);
    final MemoryAppStorage storage = MemoryAppStorage(<String, String>{
      testStorageKey: appStateJson(
        language: 'ru',
        inputLanguage: 'en',
        hand: 'right',
        darkMode: true,
        chordHintsEnabled: false,
        lessonIndexes: const <String, int>{'en': 1, 'ru': 2},
      ),
    });

    await tester.pumpWidget(ChordtypeApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Русский: курс'), findsOneWidget);
    expect(find.textContaining('Раскладка: EN'), findsOneWidget);
    expect(find.text('Правая'), findsOneWidget);
    expect(find.byTooltip('Включить светлую тему'), findsOneWidget);
    expect(find.byTooltip('Показать подсказку аккорда'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('chord-hint')), findsNothing);
    expect(
      find.text(courseFor(CourseLanguage.russian).lessons[2].title),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('invalid stored value types fall back to safe defaults', (
    WidgetTester tester,
  ) async {
    configureDesktopView(tester);
    final MemoryAppStorage storage = MemoryAppStorage(<String, String>{
      testStorageKey:
          '''{"language":123,"inputLanguage":[],"hand":false,"darkMode":"invalid","stats":{"en-chat-01":{"lastCompletedAt":7}}}''',
    });

    await tester.pumpWidget(ChordtypeApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('English: course'), findsOneWidget);
    expect(find.textContaining('Layout: EN'), findsOneWidget);
    expect(find.text('Left'), findsOneWidget);
    expect(find.byTooltip('Use dark theme'), findsOneWidget);
    expect(find.byTooltip('Hide chord hint'), findsOneWidget);
  });
}
