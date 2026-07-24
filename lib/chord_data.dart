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
  21: ChordAction.text('?'),
  14: ChordAction.text(','),
  35: ChordAction.text(')'),
  37: ChordAction.text("'"),
  46: ChordAction.text('!'),
  29: ChordAction.text('-'),
  15: ChordAction.text('('),
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
  '.': '%',
  ',': '*',
  '?': ';',
  "'": '/',
  ')': '>',
  '!': '<',
  '-': '"',
  '(': ':',
  r'$': '`',
  '&': '\\',
  '=': '@',
  ']': '#',
  '+': '|',
  '[': '~',
  '_': '^',
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
    8: 't',
    32: 'e',
    4: 'o',
    2: 'a',
    1: 'i',
    24: 'n',
    40: 's',
    20: 'h',
    36: 'r',
    18: 'u',
    34: 'd',
    17: 'l',
    33: 'y',
    6: 'm',
    9: 'g',
    3: 'w',
    28: 'c',
    44: 'b',
    22: 'p',
    42: 'f',
    38: 'k',
    25: 'v',
    41: 'j',
    19: 'z',
    13: 'q',
    7: 'x',
  },
  languageSymbols: <int, String>{
    11: r'$',
    45: '[',
    27: ']',
    23: '&',
    43: '_',
    39: '+',
    31: '=',
  },
);

const ChordLayout russianLayout = ChordLayout(
  letters: <int, String>{
    8: 'а',
    32: 'о',
    4: 'е',
    2: 'т',
    1: 'н',
    24: 'и',
    40: 'с',
    20: 'р',
    36: 'в',
    18: 'к',
    34: 'м',
    17: 'л',
    33: 'у',
    6: 'я',
    9: 'б',
    3: 'д',
    28: 'ь',
    44: 'ч',
    22: 'ю',
    42: 'п',
    38: 'ы',
    25: 'з',
    41: 'г',
    19: 'ш',
    13: 'х',
    11: 'й',
    7: 'ж',
    45: 'э',
    27: 'ё',
    23: 'щ',
    43: 'ц',
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
