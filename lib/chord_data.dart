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
const int shiftChord = 20;
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
  44: ChordAction.text('.'),
  21: ChordAction.text('?'),
  25: ChordAction.text(','),
  35: ChordAction.text(')'),
  7: ChordAction.text("'"),
  23: ChordAction.text(':'),
  43: ChordAction.text('-'),
  15: ChordAction.text('='),
};

const Map<int, String> numbersAndSymbolsLayer = <int, String>{
  8: '2',
  4: '1',
  32: '4',
  2: '0',
  1: '3',
  24: '5',
  12: '6',
  40: '7',
  18: '8',
  36: '9',
  6: '{',
  17: '}',
};

const Map<String, String> _shiftedOutputs = <String, String>{
  '.': '>',
  ',': '<',
  '?': '!',
  ')': '(',
  "'": '"',
  ':': ';',
  '-': '_',
  '#': '@',
  '*': '^',
  '=': '+',
  '/': '\\',
  '&': '|',
  '~': '`',
  r'$': '%',
  '[': ']',
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
  16,
  8,
  4,
  32,
  2,
  1,
  24,
  20,
  12,
  40,
  18,
  36,
  6,
  17,
  34,
  10,
  33,
  5,
  9,
  3,
  28,
  44,
  22,
  26,
  38,
  42,
  14,
  21,
  25,
  19,
  37,
  41,
  13,
  35,
  7,
  11,
  30,
  46,
  29,
  23,
  45,
  27,
  39,
  43,
  15,
  31,
  47,
];

const ChordLayout englishLayout = ChordLayout(
  letters: <int, String>{
    8: 'e',
    4: 'a',
    32: 'o',
    2: 't',
    1: 'i',
    24: 'n',
    12: 'h',
    40: 's',
    18: 'r',
    36: 'l',
    6: 'u',
    17: 'm',
    34: 'd',
    33: 'y',
    9: 'g',
    3: 'c',
    28: 'w',
    22: 'p',
    26: 'k',
    38: 'b',
    42: 'f',
    14: 'v',
    19: 'j',
    37: 'x',
    13: 'z',
    11: 'q',
  },
  languageSymbols: <int, String>{
    41: '#',
    46: '*',
    29: '/',
    45: '&',
    27: '~',
    39: r'$',
    31: '[',
  },
);

const ChordLayout russianLayout = ChordLayout(
  letters: <int, String>{
    8: 'о',
    4: 'е',
    32: 'а',
    2: 'т',
    1: 'н',
    24: 'и',
    12: 'с',
    40: 'р',
    18: 'в',
    36: 'л',
    6: 'к',
    17: 'м',
    34: 'у',
    33: 'я',
    9: 'д',
    3: 'ь',
    28: 'б',
    22: 'п',
    26: 'ю',
    38: 'ч',
    42: 'ы',
    14: 'з',
    19: 'г',
    37: 'ж',
    13: 'ш',
    11: 'х',
    41: 'й',
    46: 'э',
    29: 'щ',
    45: 'ц',
    27: 'ё',
    39: 'ф',
    31: 'ъ',
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
