import 'chord_data.dart';

class ChordStep {
  const ChordStep({
    required this.mask,
    this.modifier,
    this.switchTo,
  });

  final int mask;
  final ChordModifier? modifier;
  final CourseLanguage? switchTo;
}

class ChordEngine {
  const ChordEngine();

  ChordAction? resolve({
    required int mask,
    required ChordLayout layout,
    required ChordModifier? activeModifier,
  }) {
    final ChordAction? common = commonActions[mask];
    if (common != null &&
        (common.kind == ChordActionKind.modifier ||
            common.kind == ChordActionKind.control ||
            mask == spaceChord)) {
      return common;
    }

    if (activeModifier == ChordModifier.numbersAndSymbols) {
      final String? value = numbersAndSymbolsLayer[mask];
      if (value != null) {
        return ChordAction.text(value);
      }
    }

    if (common != null) {
      return common;
    }

    final String? value = layout.outputFor(mask);
    return value == null ? null : ChordAction.text(value);
  }

  List<ChordStep> planCharacter({
    required String target,
    required CourseLanguage inputLanguage,
  }) {
    final List<ChordStep> activeSteps = _stepsInLayout(
      target,
      layoutFor(inputLanguage),
    );
    if (activeSteps.isNotEmpty) {
      return activeSteps;
    }

    final CourseLanguage otherLanguage = inputLanguage == CourseLanguage.english
        ? CourseLanguage.russian
        : CourseLanguage.english;
    final List<ChordStep> otherSteps = _stepsInLayout(
      target,
      layoutFor(otherLanguage),
    );
    if (otherSteps.isEmpty) {
      return const <ChordStep>[];
    }

    return <ChordStep>[
      ChordStep(mask: layoutSwitchChord, switchTo: otherLanguage),
      ...otherSteps,
    ];
  }

  List<ChordStep> _stepsInLayout(String target, ChordLayout layout) {
    final ChordStep? directStep = _directStep(target, layout);
    if (directStep != null) {
      return <ChordStep>[directStep];
    }

    final ChordStep? shiftedDirectStep = _shiftedDirectStep(target, layout);
    if (shiftedDirectStep != null) {
      return <ChordStep>[
        const ChordStep(mask: shiftChord, modifier: ChordModifier.shift),
        shiftedDirectStep,
      ];
    }

    final ChordStep? numbersAndSymbolsStep = _stepInLayer(
      target,
      numbersAndSymbolsLayer,
    );
    if (numbersAndSymbolsStep != null) {
      return <ChordStep>[
        const ChordStep(
          mask: numbersAndSymbolsChord,
          modifier: ChordModifier.numbersAndSymbols,
        ),
        numbersAndSymbolsStep,
      ];
    }

    return const <ChordStep>[];
  }

  ChordStep? _directStep(String target, ChordLayout layout) {
    if (target == '\n') {
      return const ChordStep(mask: enterChord);
    }

    for (final MapEntry<int, ChordAction> entry in commonActions.entries) {
      final ChordAction action = entry.value;
      if (action.kind == ChordActionKind.text && action.text == target) {
        return ChordStep(mask: entry.key);
      }
    }

    for (final int mask in chordEaseOrder) {
      if (layout.outputFor(mask) == target) {
        return ChordStep(mask: mask);
      }
    }
    return null;
  }

  ChordStep? _shiftedDirectStep(String target, ChordLayout layout) {
    for (final int mask in chordEaseOrder) {
      final ChordAction? common = commonActions[mask];
      String? value = layout.outputFor(mask);
      if (common != null && common.kind == ChordActionKind.text) {
        value = common.text;
      }
      if (value != null &&
          value != target &&
          shiftedOutputFor(value) == target) {
        return ChordStep(mask: mask);
      }
    }
    return null;
  }

  ChordStep? _stepInLayer(String target, Map<int, String> layer) {
    for (final int mask in chordEaseOrder) {
      if (layer[mask] == target) {
        return ChordStep(mask: mask);
      }
    }
    return null;
  }
}
