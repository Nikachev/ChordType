import 'package:flutter_test/flutter_test.dart';

import 'package:chordtype/chord_data.dart';
import 'package:chordtype/chord_engine.dart';

void main() {
  const ChordEngine engine = ChordEngine();

  group('resolve', () {
    test('uses the active base layout', () {
      final ChordAction? english = engine.resolve(
        mask: 8,
        layout: englishLayout,
        activeModifier: null,
      );
      final ChordAction? russian = engine.resolve(
        mask: 8,
        layout: russianLayout,
        activeModifier: null,
      );

      expect(english?.text, 'o');
      expect(russian?.text, 'е');
    });

    test('gives controls and modifiers priority over armed layers', () {
      final ChordAction? modifier = engine.resolve(
        mask: numbersAndSymbolsChord,
        layout: englishLayout,
        activeModifier: ChordModifier.numbersAndSymbols,
      );
      final ChordAction? control = engine.resolve(
        mask: backspaceChord,
        layout: englishLayout,
        activeModifier: ChordModifier.numbersAndSymbols,
      );

      expect(modifier?.kind, ChordActionKind.modifier);
      expect(modifier?.modifier, ChordModifier.numbersAndSymbols);
      expect(control?.kind, ChordActionKind.control);
      expect(control?.control, ChordControl.backspace);
    });

    test('resolves the one-shot layer before the base layout', () {
      final ChordAction? layerAction = engine.resolve(
        mask: 8,
        layout: englishLayout,
        activeModifier: ChordModifier.numbersAndSymbols,
      );

      expect(layerAction?.text, '0');
    });
  });

  group('planCharacter', () {
    test('plans direct, shifted base, numbers/symbols, and Enter input', () {
      expect(
        _planMasks(engine, 'e'),
        <int>[32],
      );
      expect(
        _planMasks(engine, 'E'),
        <int>[shiftChord, 32],
      );
      expect(
        _planMasks(engine, '!'),
        <int>[7],
      );
      expect(
        _planMasks(engine, '0'),
        <int>[numbersAndSymbolsChord, 8],
      );
      expect(
        _planMasks(engine, '}'),
        <int>[numbersAndSymbolsChord, 6],
      );
      expect(
        _planMasks(engine, '\n'),
        <int>[enterChord],
      );
    });

    test('prepends a layout switch only when required', () {
      final List<ChordStep> steps = engine.planCharacter(
        target: 'о',
        inputLanguage: CourseLanguage.english,
      );

      expect(steps.map((ChordStep step) => step.mask), <int>[47, 32]);
      expect(steps.first.switchTo, CourseLanguage.russian);
      expect(steps.last.switchTo, isNull);
    });

    test('switches layouts before EN-only shifted punctuation', () {
      final List<ChordStep> steps = engine.planCharacter(
        target: '@',
        inputLanguage: CourseLanguage.russian,
      );

      expect(
        steps.map((ChordStep step) => step.mask),
        <int>[layoutSwitchChord, 27],
      );
      expect(steps.first.switchTo, CourseLanguage.english);
    });

    test('returns no steps for unsupported characters', () {
      expect(
        engine.planCharacter(
          target: '🙂',
          inputLanguage: CourseLanguage.english,
        ),
        isEmpty,
      );
    });
  });
}

Iterable<int> _planMasks(ChordEngine engine, String target) {
  return engine
      .planCharacter(
        target: target,
        inputLanguage: CourseLanguage.english,
      )
      .map((ChordStep step) => step.mask);
}
