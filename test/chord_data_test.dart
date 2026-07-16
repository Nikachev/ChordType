import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chordtype/chord_data.dart';

void main() {
  test('ease order contains every valid chord exactly once', () {
    final Set<int> validMasks = <int>{
      for (int mask = 1; mask < 64; mask += 1)
        if (isValidChordMask(mask)) mask,
    };

    expect(chordEaseOrder, hasLength(47));
    expect(chordEaseOrder.toSet(), hasLength(chordEaseOrder.length));
    expect(chordEaseOrder.toSet(), validMasks);
  });

  test('no configured chord requires both thumb keys', () {
    final Set<int> masks = <int>{
      ...commonActions.keys,
      ...numbersAndSymbolsLayer.keys,
      ...englishLayout.letters.keys,
      ...englishLayout.languageSymbols.keys,
      ...russianLayout.letters.keys,
      ...russianLayout.languageSymbols.keys,
      ...chordEaseOrder,
    };

    for (final int mask in masks) {
      expect(
        usesBothThumbKeys(mask),
        isFalse,
        reason: 'mask $mask uses both thumb keys',
      );
    }
  });

  test('each language layout occupies every mask outside common actions', () {
    for (final ChordLayout layout in <ChordLayout>[
      englishLayout,
      russianLayout,
    ]) {
      final Set<int> layoutMasks = <int>{
        ...layout.letters.keys,
        ...layout.languageSymbols.keys,
      };

      expect(layoutMasks, hasLength(33));
      expect(layoutMasks.intersection(commonActions.keys.toSet()), isEmpty);
      expect(
        <int>{...layoutMasks, ...commonActions.keys},
        chordEaseOrder.toSet(),
      );
    }
  });

  test('layouts contain complete alphabets and EN-specific symbols', () {
    const Set<String> englishAlphabet = <String>{
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
      'g',
      'h',
      'i',
      'j',
      'k',
      'l',
      'm',
      'n',
      'o',
      'p',
      'q',
      'r',
      's',
      't',
      'u',
      'v',
      'w',
      'x',
      'y',
      'z',
    };
    const Set<String> russianAlphabet = <String>{
      'а',
      'б',
      'в',
      'г',
      'д',
      'е',
      'ё',
      'ж',
      'з',
      'и',
      'й',
      'к',
      'л',
      'м',
      'н',
      'о',
      'п',
      'р',
      'с',
      'т',
      'у',
      'ф',
      'х',
      'ц',
      'ч',
      'ш',
      'щ',
      'ъ',
      'ы',
      'ь',
      'э',
      'ю',
      'я',
    };

    expect(englishLayout.letters.values.toSet(), englishAlphabet);
    expect(russianLayout.letters.values.toSet(), russianAlphabet);
    expect(russianLayout.languageSymbols, isEmpty);

    final Set<int> russianOnlyLetterMasks = russianLayout.letters.keys
        .toSet()
        .difference(englishLayout.letters.keys.toSet());
    expect(
      englishLayout.languageSymbols.keys.toSet(),
      russianOnlyLetterMasks,
    );
    expect(
      englishLayout.languageSymbols.values.toSet(),
      <String>{'#', '*', '/', '&', '~', r'$', '['},
    );
  });

  test('all eight RU punctuation pairs use identical shared chords', () {
    const Map<int, String> expected = <int, String>{
      44: '.',
      21: '?',
      25: ',',
      35: ')',
      7: "'",
      23: ':',
      43: '-',
      15: '=',
    };

    for (final MapEntry<int, String> entry in expected.entries) {
      final ChordAction? action = commonActions[entry.key];
      expect(action, isNotNull);
      expect(action!.kind, ChordActionKind.text);
      expect(action.text, entry.value);
    }

    expect(
      expected.values.map(shiftedOutputFor).toSet(),
      <String>{'>', '<', '!', '(', '"', ';', '_', '+'},
    );
  });

  test('numbers/symbols layer is direct, unique, and absent from layouts', () {
    expect(
      numbersAndSymbolsLayer.keys
          .toSet()
          .intersection(commonActions.keys.toSet()),
      isEmpty,
    );
    expect(
      numbersAndSymbolsLayer.values.toSet(),
      <String>{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '{', '}'},
    );
    expect(
      numbersAndSymbolsLayer.values.toSet(),
      hasLength(numbersAndSymbolsLayer.length),
    );

    final Set<String> baseOutputs = <String>{
      for (final ChordAction action in commonActions.values)
        if (action.kind == ChordActionKind.text) action.text!,
      ...englishLayout.letters.values,
      ...englishLayout.languageSymbols.values,
      ...russianLayout.letters.values,
      ...russianLayout.languageSymbols.values,
    };
    final Set<String> baseAndShiftOutputs = <String>{
      ...baseOutputs,
      ...baseOutputs.map(shiftedOutputFor),
    };
    final Set<String> layerOutputs = numbersAndSymbolsLayer.values.toSet();

    expect(layerOutputs.intersection(baseAndShiftOutputs), isEmpty);
  });

  test('layout switch is a shared control chord', () {
    final ChordAction? action = commonActions[layoutSwitchChord];

    expect(action, isNotNull);
    expect(action!.kind, ChordActionKind.control);
    expect(action.control, ChordControl.switchLayout);
  });

  test('hand modes use unique physical keys', () {
    for (final List<PhysicalChordKey> keys in <List<PhysicalChordKey>>[
      leftHandKeys,
      rightHandKeys,
    ]) {
      expect(
        keys.map((PhysicalChordKey key) => key.physicalKey).toSet(),
        hasLength(keys.length),
      );
    }
  });

  test('hand modes use the documented QWER/CV and UIOP/BN keys', () {
    expect(
      leftHandKeys
          .map((PhysicalChordKey key) => (key.label, key.physicalKey))
          .toList(),
      <(String, PhysicalKeyboardKey)>[
        ('Q', PhysicalKeyboardKey.keyQ),
        ('W', PhysicalKeyboardKey.keyW),
        ('E', PhysicalKeyboardKey.keyE),
        ('R', PhysicalKeyboardKey.keyR),
        ('C', PhysicalKeyboardKey.keyC),
        ('V', PhysicalKeyboardKey.keyV),
      ],
    );
    expect(
      rightHandKeys
          .map((PhysicalChordKey key) => (key.label, key.physicalKey))
          .toList(),
      <(String, PhysicalKeyboardKey)>[
        ('P', PhysicalKeyboardKey.keyP),
        ('O', PhysicalKeyboardKey.keyO),
        ('I', PhysicalKeyboardKey.keyI),
        ('U', PhysicalKeyboardKey.keyU),
        ('B', PhysicalKeyboardKey.keyB),
        ('N', PhysicalKeyboardKey.keyN),
      ],
    );
  });

  test('Shift output applies to base letters and punctuation only', () {
    expect(shiftedOutputFor('a'), 'A');
    expect(shiftedOutputFor('я'), 'Я');
    expect(shiftedOutputFor('?'), '!');
    expect(shiftedOutputFor(')'), '(');
    expect(shiftedOutputFor('['), ']');
    expect(shiftedOutputFor('{'), '{');
    expect(shiftedOutputFor('}'), '}');
    expect(shiftedOutputFor('1'), '1');
  });
}
