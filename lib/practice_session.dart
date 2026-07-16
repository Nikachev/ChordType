class PracticeInputResult {
  const PracticeInputResult({
    required this.accepted,
    required this.correct,
    required this.completesTarget,
    this.expected,
  });

  const PracticeInputResult.blocked()
      : accepted = false,
        correct = false,
        completesTarget = false,
        expected = null;

  final bool accepted;
  final bool correct;
  final bool completesTarget;
  final String? expected;
}

class PracticeSession {
  PracticeSession(String target) : _target = target;

  String _target;
  final List<String> _typedCharacters = <String>[];
  int _errors = 0;
  int _strokes = 0;
  bool _completed = false;

  int get errors => _errors;

  int get strokes => _strokes;

  bool get completed => _completed;

  int get position => _typedCharacters.length;

  List<String> get typedCharacters =>
      List<String>.unmodifiable(_typedCharacters);

  bool get isFull => position >= _target.length;

  bool get hasMistakes {
    for (int index = 0; index < _typedCharacters.length; index += 1) {
      if (_typedCharacters[index] != _target[index]) {
        return true;
      }
    }
    return false;
  }

  double get accuracy {
    if (_strokes == 0) {
      return 100;
    }
    return ((_strokes - _errors) / _strokes) * 100;
  }

  PracticeInputResult enter(String value) {
    if (_completed || isFull) {
      return const PracticeInputResult.blocked();
    }

    final String expected = _target[position];
    final bool correct = value == expected;
    _typedCharacters.add(value);
    _strokes += 1;
    if (!correct) {
      _errors += 1;
    }

    return PracticeInputResult(
      accepted: true,
      correct: correct,
      completesTarget: isFull && _typedCharacters.join() == _target,
      expected: expected,
    );
  }

  bool backspace() {
    if (_completed || _typedCharacters.isEmpty) {
      return false;
    }
    _typedCharacters.removeLast();
    return true;
  }

  bool markCompleted() {
    if (_completed || !isFull || _typedCharacters.join() != _target) {
      return false;
    }
    _completed = true;
    return true;
  }

  void reset(String target) {
    _target = target;
    _typedCharacters.clear();
    _errors = 0;
    _strokes = 0;
    _completed = false;
  }
}
