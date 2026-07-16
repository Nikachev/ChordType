import 'package:flutter_test/flutter_test.dart';

import 'package:chordtype/practice_session.dart';

void main() {
  test('incorrect input advances and Backspace removes the last character', () {
    final PracticeSession session = PracticeSession('ab');

    final PracticeInputResult mistake = session.enter('x');

    expect(mistake.accepted, isTrue);
    expect(mistake.correct, isFalse);
    expect(mistake.expected, 'a');
    expect(session.position, 1);
    expect(session.errors, 1);
    expect(session.hasMistakes, isTrue);
    expect(session.backspace(), isTrue);
    expect(session.position, 0);
    expect(session.errors, 1);
    expect(session.hasMistakes, isFalse);
  });

  test('completion requires an exact full target', () {
    final PracticeSession session = PracticeSession('ab');

    expect(session.enter('x').completesTarget, isFalse);
    expect(session.enter('b').completesTarget, isFalse);
    expect(session.isFull, isTrue);
    expect(session.markCompleted(), isFalse);
    expect(session.enter('a').accepted, isFalse);
    expect(session.strokes, 2);

    session.backspace();
    session.backspace();
    expect(session.enter('a').completesTarget, isFalse);
    expect(session.hasMistakes, isFalse);
    expect(session.enter('b').completesTarget, isTrue);
    expect(session.markCompleted(), isTrue);
    expect(session.completed, isTrue);
    expect(session.accuracy, 75);
    expect(session.backspace(), isFalse);
  });

  test('reset clears run state and changes the target', () {
    final PracticeSession session = PracticeSession('a');
    session.enter('x');

    session.reset('b');

    expect(session.position, 0);
    expect(session.errors, 0);
    expect(session.strokes, 0);
    expect(session.accuracy, 100);
    expect(session.enter('b').completesTarget, isTrue);
  });
}
