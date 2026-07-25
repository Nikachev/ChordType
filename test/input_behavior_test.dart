import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chordtype/chord_data.dart';
import 'package:chordtype/chord_engine.dart';
import 'package:chordtype/course_data.dart';
import 'package:chordtype/main.dart';

import 'test_support.dart';

void main() {
  const ChordEngine engine = ChordEngine();

  testWidgets('layout switch changes input without changing the course', (
    WidgetTester tester,
  ) async {
    configureDesktopView(tester);
    await tester.pumpWidget(ChordtypeApp(storage: MemoryAppStorage()));
    await tester.pumpAndSettle();

    await _sendMask(tester, layoutSwitchChord);

    expect(find.text('Layout: RU'), findsOneWidget);
    expect(find.text('English: course'), findsOneWidget);
  });

  testWidgets('Backspace removes the latest incorrect character', (
    WidgetTester tester,
  ) async {
    configureDesktopView(tester);
    await tester.pumpWidget(ChordtypeApp(storage: MemoryAppStorage()));
    await tester.pumpAndSettle();

    await _sendMask(tester, 32);
    await tester.pumpAndSettle();

    expect(_progress(tester), greaterThan(0));
    expect(
      find.text('Press Backspace to fix the mistake'),
      findsAtLeastNWidgets(1),
    );
    expect(find.byKey(const ValueKey<String>('chord-hint')), findsOneWidget);
    expect(_keyColor(tester, 1), _colors(tester).tertiaryContainer);
    expect(_keyColor(tester, 4), _colors(tester).tertiaryContainer);

    await _sendMask(tester, backspaceChord);
    await tester.pumpAndSettle();

    expect(_progress(tester), 0);
    expect(find.text('Press Backspace to fix the mistake'), findsNothing);
    expect(_keyColor(tester, 8), _colors(tester).tertiaryContainer);
  });

  testWidgets(
    'hint toggle hides the next chord but keeps correction guidance',
    (WidgetTester tester) async {
      configureDesktopView(tester);
      final MemoryAppStorage storage = MemoryAppStorage();
      await tester.pumpWidget(ChordtypeApp(storage: storage));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('chord-hint')), findsOneWidget);
      expect(_keyColor(tester, 8), _colors(tester).tertiaryContainer);

      await tester.tap(find.byTooltip('Hide chord hint'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Show chord hint'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('chord-hint')), findsNothing);
      expect(_keyColor(tester, 2), _colors(tester).surfaceContainerLow);
      expect(
        (jsonDecode(storage[testStorageKey]!)
            as Map<String, dynamic>)['chordHintsEnabled'],
        isFalse,
      );

      await _sendMask(tester, 32);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('chord-hint')), findsOneWidget);
      expect(
        find.text('Press Backspace to fix the mistake'),
        findsAtLeastNWidgets(1),
      );
      expect(_keyColor(tester, 1), _colors(tester).tertiaryContainer);
      expect(_keyColor(tester, 4), _colors(tester).tertiaryContainer);

      await _sendMask(tester, backspaceChord);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('chord-hint')), findsNothing);
      expect(find.byTooltip('Show chord hint'), findsOneWidget);
    },
  );

  testWidgets('numbers-and-symbols modifier replaces armed Shift', (
    WidgetTester tester,
  ) async {
    configureDesktopView(tester);
    final TrainingCourse course = courseFor(CourseLanguage.english);
    final TrainingLesson lesson = course.lessons.singleWhere(
      (TrainingLesson lesson) => lesson.id == 'en-chat-11',
    );
    final int lessonIndex = course.lessons.indexOf(lesson);
    final int braceIndex = lesson.target.indexOf('{');
    final MemoryAppStorage storage = MemoryAppStorage(<String, String>{
      testStorageKey: appStateJson(
        lessonIndexes: <String, int>{'en': lessonIndex, 'ru': 0},
      ),
    });

    await tester.pumpWidget(ChordtypeApp(storage: storage));
    await tester.pumpAndSettle();
    await _typeText(tester, lesson.target.substring(0, braceIndex), engine);

    await _sendMask(tester, shiftChord);
    await _sendMask(tester, numbersAndSymbolsChord);
    await _sendMask(tester, 17);
    await tester.pumpAndSettle();

    expect(
      _progress(tester),
      closeTo((braceIndex + 1) / lesson.target.length, 0.000001),
    );
    expect(find.text('Press Backspace to fix the mistake'), findsNothing);
  });

  for (final _InputCase inputCase in <_InputCase>[
    const _InputCase(
      name: 'Shift punctuation',
      lessonId: 'en-chat-07',
      lastCharacter: '!',
    ),
    const _InputCase(
      name: 'Enter',
      lessonId: 'en-chat-09',
      lastCharacter: '\n',
    ),
    const _InputCase(
      name: 'Numbers-and-symbols layer',
      lessonId: 'en-chat-10',
      lastCharacter: '1',
    ),
    const _InputCase(
      name: 'Direct closing brace on numbers-and-symbols layer',
      lessonId: 'en-chat-11',
      lastCharacter: '}',
    ),
  ]) {
    testWidgets('${inputCase.name} chord enters the planned lesson text', (
      WidgetTester tester,
    ) async {
      configureDesktopView(tester);
      final TrainingCourse course = courseFor(CourseLanguage.english);
      final TrainingLesson lesson = course.lessons.singleWhere(
        (TrainingLesson lesson) => lesson.id == inputCase.lessonId,
      );
      final int lessonIndex = course.lessons.indexOf(lesson);
      final int prefixEnd = lesson.target.indexOf(inputCase.lastCharacter) +
          inputCase.lastCharacter.length;
      final String prefix = lesson.target.substring(0, prefixEnd);
      final MemoryAppStorage storage = MemoryAppStorage(<String, String>{
        testStorageKey: appStateJson(
          lessonIndexes: <String, int>{
            'en': lessonIndex,
            'ru': 0,
          },
        ),
      });

      await tester.pumpWidget(ChordtypeApp(storage: storage));
      await tester.pumpAndSettle();
      await _typeText(tester, prefix, engine);

      expect(
        _progress(tester),
        closeTo(prefix.length / lesson.target.length, 0.000001),
      );
    });
  }
}

double _progress(WidgetTester tester) {
  return tester
          .widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .value ??
      0;
}

ColorScheme _colors(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
}

Color _keyColor(WidgetTester tester, int bit) {
  final AnimatedContainer key = tester.widget<AnimatedContainer>(
    find.byKey(ValueKey<String>('chord-key-$bit')),
  );
  return (key.decoration! as BoxDecoration).color!;
}

Future<void> _typeText(
  WidgetTester tester,
  String text,
  ChordEngine engine,
) async {
  for (final String character in text.split('')) {
    final List<ChordStep> steps = engine.planCharacter(
      target: character,
      inputLanguage: CourseLanguage.english,
    );
    expect(steps, isNotEmpty, reason: 'No chord plan for "$character"');
    for (final ChordStep step in steps) {
      await _sendMask(tester, step.mask);
    }
  }
}

Future<void> _sendMask(WidgetTester tester, int mask) async {
  final List<PhysicalChordKey> keys = leftHandKeys
      .where((PhysicalChordKey key) => mask & key.bit != 0)
      .toList(growable: false);

  for (final PhysicalChordKey key in keys) {
    await tester.sendKeyDownEvent(
      _logicalKeyFor(key.physicalKey),
      physicalKey: key.physicalKey,
    );
  }
  for (final PhysicalChordKey key in keys.reversed) {
    await tester.sendKeyUpEvent(
      _logicalKeyFor(key.physicalKey),
      physicalKey: key.physicalKey,
    );
  }
  await tester.pump();
}

LogicalKeyboardKey _logicalKeyFor(PhysicalKeyboardKey physicalKey) {
  return switch (physicalKey) {
    PhysicalKeyboardKey.keyQ => LogicalKeyboardKey.keyQ,
    PhysicalKeyboardKey.keyW => LogicalKeyboardKey.keyW,
    PhysicalKeyboardKey.keyE => LogicalKeyboardKey.keyE,
    PhysicalKeyboardKey.keyR => LogicalKeyboardKey.keyR,
    PhysicalKeyboardKey.keyC => LogicalKeyboardKey.keyC,
    PhysicalKeyboardKey.keyV => LogicalKeyboardKey.keyV,
    _ => throw ArgumentError.value(physicalKey, 'physicalKey'),
  };
}

class _InputCase {
  const _InputCase({
    required this.name,
    required this.lessonId,
    required this.lastCharacter,
  });

  final String name;
  final String lessonId;
  final String lastCharacter;
}
