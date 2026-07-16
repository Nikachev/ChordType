import 'package:flutter_test/flutter_test.dart';

import 'package:chordtype/lesson_stats.dart';

void main() {
  test('lesson stats coerce numeric JSON values', () {
    final LessonStats stats = LessonStats.fromJson(<String, dynamic>{
      'attempts': 3.0,
      'completions': 2,
      'totalErrors': 5.9,
      'totalStrokes': 120.0,
      'bestWpm': 42,
      'bestAccuracy': 98.5,
      'lastWpm': 40.25,
      'lastAccuracy': 96,
      'lastCompletedAt': '2026-07-14T10:00:00.000Z',
    });

    expect(stats.attempts, 3);
    expect(stats.completions, 2);
    expect(stats.totalErrors, 5);
    expect(stats.totalStrokes, 120);
    expect(stats.bestWpm, 42.0);
    expect(stats.bestAccuracy, 98.5);
    expect(stats.lastWpm, 40.25);
    expect(stats.lastAccuracy, 96.0);
    expect(stats.lastCompletedAt, '2026-07-14T10:00:00.000Z');
  });

  test('lesson stats round-trip every persisted field', () {
    final LessonStats original = LessonStats()
      ..attempts = 4
      ..completions = 3
      ..totalErrors = 7
      ..totalStrokes = 240
      ..bestWpm = 51.5
      ..bestAccuracy = 99.1
      ..lastWpm = 47.25
      ..lastAccuracy = 97.0
      ..lastCompletedAt = '2026-07-14T10:00:00.000Z';

    final Map<String, Object?> json = original.toJson();
    final LessonStats restored = LessonStats.fromJson(
      Map<String, dynamic>.from(json),
    );

    expect(restored.toJson(), json);
  });

  test('lesson stats use safe defaults for invalid values', () {
    final LessonStats stats = LessonStats.fromJson(<String, dynamic>{
      'attempts': 'invalid',
      'bestWpm': null,
      'lastCompletedAt': 123,
    });

    expect(stats.toJson(), <String, Object?>{
      'attempts': 0,
      'completions': 0,
      'totalErrors': 0,
      'totalStrokes': 0,
      'bestWpm': 0.0,
      'bestAccuracy': 0.0,
      'lastWpm': 0.0,
      'lastAccuracy': 0.0,
      'lastCompletedAt': null,
    });
  });
}
