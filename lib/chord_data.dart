import 'package:flutter/services.dart';

enum CourseLanguage {
  english('en', 'English'),
  russian('ru', 'Русский');

  const CourseLanguage(this.code, this.title);

  final String code;
  final String title;
}

enum HandMode {
  left('left', 'Левая'),
  right('right', 'Правая');

  const HandMode(this.code, this.title);

  final String code;
  final String title;
}

enum ChordActionKind { text, modifier, control }

enum ChordModifier { shift, numbersAndSymbols }

enum ChordControl { backspace, enter, switchLayout }

class PhysicalChordKey {
  const PhysicalChordKey({
    required this.bit,
    required this.label,
    required this.role,
    required this.physicalKey,
  });

  final int bit;
  final String label;
  final String role;
  final PhysicalKeyboardKey physicalKey;
}

class ChordAction {
  const ChordAction.text(this.text)
      : kind = ChordActionKind.text,
        modifier = null,
        control = null;

  const ChordAction.modifier(this.modifier)
      : kind = ChordActionKind.modifier,
        text = null,
        control = null;

  const ChordAction.control(this.control)
      : kind = ChordActionKind.control,
        text = null,
        modifier = null;

  final ChordActionKind kind;
  final String? text;
  final ChordModifier? modifier;
  final ChordControl? control;
}

class ChordLayout {
  const ChordLayout({
    required this.letters,
    required this.languageSymbols,
  });

  final Map<int, String> letters;
  final Map<int, String> languageSymbols;

  String? outputFor(int mask) {
    return letters[mask] ?? languageSymbols[mask];
  }
}

const int primaryThumbBit = 16;
const int secondaryThumbBit = 32;

const int spaceChord = primaryThumbBit;
const int shiftChord = 12;
const int numbersAndSymbolsChord = 30;
const int backspaceChord = 5;
const int enterChord = 10;
const int layoutSwitchChord = 47;

const Map<int, ChordAction> commonActions = <int, ChordAction>{
  spaceChord: ChordAction.text(' '),
  shiftChord: ChordAction.modifier(ChordModifier.shift),
  numbersAndSymbolsChord: ChordAction.modifier(ChordModifier.numbersAndSymbols),
  backspaceChord: ChordAction.control(ChordControl.backspace),
  enterChord: ChordAction.control(ChordControl.enter),
  layoutSwitchChord: ChordAction.control(ChordControl.switchLayout),
  26: ChordAction.text('.'),
  14: ChordAction.text(','),
  41: ChordAction.text(')'),
  35: ChordAction.text('?'),
  7: ChordAction.text('!'),
  46: ChordAction.text('-'),
  39: ChordAction.text(':'),
  15: ChordAction.text('('),
  31: ChordAction.text('"'),
};

const Map<int, String> numbersAndSymbolsLayer = <int, String>{
  8: '0',
  32: '2',
  4: '1',
  2: '5',
  1: '3',
  24: '4',
  40: '6',
  20: '7',
  36: '8',
  18: '9',
  17: '{',
  6: '}',
};

const Map<String, String> _shiftedOutputs = <String, String>{
  '.': '+',
  ',': '^',
  ')': '%',
  '?': '=',
  '!': '*',
  '-': ';',
  ':': '>',
  '(': '/',
  '"': '<',
  "'": '`',
  '@': r'$',
  '#': '~',
  '&': '|',
  '[': ']',
  '_': '\\',
  'ь': 'ъ',
};

String shiftedOutputFor(String value) {
  return _shiftedOutputs[value] ?? value.toUpperCase();
}

const List<PhysicalChordKey> leftHandKeys = <PhysicalChordKey>[
  PhysicalChordKey(
    bit: 1,
    label: 'Q',
    role: 'миз',
    physicalKey: PhysicalKeyboardKey.keyQ,
  ),
  PhysicalChordKey(
    bit: 2,
    label: 'W',
    role: 'без',
    physicalKey: PhysicalKeyboardKey.keyW,
  ),
  PhysicalChordKey(
    bit: 4,
    label: 'E',
    role: 'ср',
    physicalKey: PhysicalKeyboardKey.keyE,
  ),
  PhysicalChordKey(
    bit: 8,
    label: 'R',
    role: 'ук',
    physicalKey: PhysicalKeyboardKey.keyR,
  ),
  PhysicalChordKey(
    bit: primaryThumbBit,
    label: 'C',
    role: 'б1',
    physicalKey: PhysicalKeyboardKey.keyC,
  ),
  PhysicalChordKey(
    bit: secondaryThumbBit,
    label: 'V',
    role: 'б2',
    physicalKey: PhysicalKeyboardKey.keyV,
  ),
];

const List<PhysicalChordKey> rightHandKeys = <PhysicalChordKey>[
  PhysicalChordKey(
    bit: 1,
    label: 'P',
    role: 'миз',
    physicalKey: PhysicalKeyboardKey.keyP,
  ),
  PhysicalChordKey(
    bit: 2,
    label: 'O',
    role: 'без',
    physicalKey: PhysicalKeyboardKey.keyO,
  ),
  PhysicalChordKey(
    bit: 4,
    label: 'I',
    role: 'ср',
    physicalKey: PhysicalKeyboardKey.keyI,
  ),
  PhysicalChordKey(
    bit: 8,
    label: 'U',
    role: 'ук',
    physicalKey: PhysicalKeyboardKey.keyU,
  ),
  PhysicalChordKey(
    bit: primaryThumbBit,
    label: 'B',
    role: 'б1',
    physicalKey: PhysicalKeyboardKey.keyB,
  ),
  PhysicalChordKey(
    bit: secondaryThumbBit,
    label: 'N',
    role: 'б2',
    physicalKey: PhysicalKeyboardKey.keyN,
  ),
];

const List<int> chordEaseOrder = <int>[
  8, 16, 32, 4, 2, 1, 24, 40, 20, 36, 12, 18, 34, 17, 10, 33, 6, 9, 5, 3,
  28, 44, 26, 22, 42, 38, 14, 25, 21, 41, 19, 37, 13, 35, 11, 7, 30, 46, 29,
  45, 27, 23, 43, 39, 15, 31, 47,
];

const ChordLayout englishLayout = ChordLayout(
  letters: <int, String>{
    8: 'o',
    32: 'e',
    4: 't',
    2: 'a',
    1: 'i',
    24: 'n',
    40: 'h',
    20: 's',
    36: 'r',
    18: 'u',
    34: 'd',
    17: 'l',
    33: 'y',
    6: 'w',
    9: 'm',
    3: 'g',
    28: 'c',
    44: 'k',
    22: 'f',
    42: 'p',
    38: 'b',
    25: 'v',
    21: 'x',
    37: 'z',
    13: 'j',
    11: 'q',
  },
  languageSymbols: <int, String>{
    19: "'",
    29: '[',
    45: '&',
    27: '@',
    23: '_',
    43: '#',
  },
);

const ChordLayout russianLayout = ChordLayout(
  letters: <int, String>{
    8: 'е',
    32: 'о',
    4: 'а',
    2: 'т',
    1: 'н',
    24: 'и',
    40: 'р',
    20: 'с',
    36: 'в',
    18: 'к',
    34: 'м',
    17: 'л',
    33: 'у',
    6: 'д',
    9: 'я',
    3: 'б',
    28: 'ь',
    44: 'ы',
    22: 'п',
    42: 'ю',
    38: 'ч',
    25: 'з',
    21: 'ж',
    37: 'ш',
    13: 'г',
    11: 'х',
    19: 'й',
    29: 'ё',
    45: 'э',
    27: 'ц',
    23: 'щ',
    43: 'ф',
  },
  languageSymbols: <int, String>{},
);

ChordLayout layoutFor(CourseLanguage language) {
  return switch (language) {
    CourseLanguage.english => englishLayout,
    CourseLanguage.russian => russianLayout,
  };
}

List<PhysicalChordKey> keysForHand(HandMode handMode) {
  return switch (handMode) {
    HandMode.left => leftHandKeys,
    HandMode.right => rightHandKeys,
  };
}

String chordLabel(int mask, List<PhysicalChordKey> keys) {
  final Iterable<String> labels = keys
      .where((PhysicalChordKey key) => mask & key.bit != 0)
      .map((PhysicalChordKey key) => key.label);
  return labels.isEmpty ? '—' : labels.join(' + ');
}

bool usesBothThumbKeys(int mask) =>
    mask & primaryThumbBit != 0 && mask & secondaryThumbBit != 0;

bool isValidChordMask(int mask) =>
    mask > 0 && mask < 64 && !usesBothThumbKeys(mask);
