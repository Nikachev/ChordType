import 'package:flutter_test/flutter_test.dart';

import 'package:chordtype/chord_data.dart';
import 'package:chordtype/chord_engine.dart';
import 'package:chordtype/course_data.dart';

void main() {
  const ChordEngine engine = ChordEngine();

  group('course structure', () {
    test('uses stable ids and progressive stages', () {
      final Set<String> ids = <String>{};

      for (final TrainingCourse course in courses) {
        final List<TrainingLesson> lessons = course.lessons;
        expect(lessons, hasLength(18));
        expect(
          course.lessonsForStage(LessonStage.foundations),
          hasLength(4),
        );
        expect(
          course.lessonsForStage(LessonStage.mechanics),
          hasLength(8),
        );
        expect(
          course.lessonsForStage(LessonStage.conversation),
          hasLength(6),
        );

        for (int index = 0; index < lessons.length; index += 1) {
          final TrainingLesson lesson = lessons[index];
          final String sequence = (index + 1).toString().padLeft(2, '0');

          expect(lesson.id, '${course.language.code}-chat-$sequence');
          expect(ids.add(lesson.id), isTrue);
          expect(lesson.title.trim(), isNotEmpty);
          expect(lesson.focus.trim(), isNotEmpty);
          expect(lesson.target.trim(), lesson.target);
          if (index > 0) {
            expect(
              lesson.stage.index,
              greaterThanOrEqualTo(lessons[index - 1].stage.index),
            );
          }
        }
      }
    });

    test('introduces easy chords first and covers each alphabet', () {
      for (final TrainingCourse course in courses) {
        final ChordLayout layout = layoutFor(course.language);
        final Set<String> easiestLetters = chordEaseOrder
            .where(layout.letters.containsKey)
            .take(4)
            .map((int mask) => layout.letters[mask]!)
            .toSet();
        final Set<String> firstLessonLetters =
            course.lessons.first.target.replaceAll(' ', '').split('').toSet();
        final String fullCourse = course.lessons
            .map((TrainingLesson lesson) => lesson.target.toLowerCase())
            .join();

        expect(firstLessonLetters, easiestLetters);
        for (final String letter in layout.letters.values) {
          expect(
            fullCourse,
            contains(letter),
            reason:
                '${course.language.code} course does not exercise "$letter"',
          );
        }
      }
    });

    test('covers base pairs and the direct numbers-and-symbols layer', () {
      final Set<String> sharedBaseOutputs = commonActions.values
          .where((ChordAction action) => action.kind == ChordActionKind.text)
          .map((ChordAction action) => action.text!)
          .toSet();

      for (final TrainingCourse course in courses) {
        final ChordLayout layout = layoutFor(course.language);
        final Set<String> courseCharacters = course.lessons
            .map((TrainingLesson lesson) => lesson.target)
            .join()
            .split('')
            .toSet();
        final Set<String> directOutputs = <String>{
          ...layout.letters.values,
          ...layout.languageSymbols.values,
          ...sharedBaseOutputs,
        };
        final Set<String> requiredBaseOutputs = <String>{
          ...directOutputs,
          for (final String output in directOutputs)
            if (output.toLowerCase() == output.toUpperCase())
              shiftedOutputFor(output),
        };
        final Set<String> layerLessonCharacters = course
            .lessonsWithSkill(LessonSkill.numbersAndSymbols)
            .map((TrainingLesson lesson) => lesson.target)
            .join()
            .split('')
            .toSet();
        final Set<String> requiredLayerOutputs =
            numbersAndSymbolsLayer.values.toSet();

        expect(
          requiredBaseOutputs.difference(courseCharacters),
          isEmpty,
          reason: '${course.language.code} course misses base or Shift outputs',
        );
        expect(
          requiredLayerOutputs.difference(layerLessonCharacters),
          isEmpty,
          reason:
              '${course.language.code} numbers/symbols lessons miss outputs',
        );
      }
    });

    test('conversation lessons grow into substantial exchanges', () {
      for (final TrainingCourse course in courses) {
        final List<TrainingLesson> lessons = course
            .lessonsForStage(LessonStage.conversation)
            .toList(growable: false);

        for (final TrainingLesson lesson in lessons) {
          expect(lesson.target, contains('\n'));
        }
        for (int index = 1; index < lessons.length; index += 1) {
          expect(
            lessons[index].target.length,
            greaterThan(lessons[index - 1].target.length),
            reason: '${lessons[index].id} must increase text volume',
          );
        }
        expect(lessons.last.target.length, greaterThanOrEqualTo(300));
      }
    });

    test('Russian links immediately follow the bilingual lesson', () {
      final TrainingCourse course = courseFor(CourseLanguage.russian);
      final int bilingualIndex = course.lessons.indexWhere(
        (TrainingLesson lesson) => lesson.topic == LessonTopic.bilingual,
      );
      final int linksIndex = course.lessons.indexWhere(
        (TrainingLesson lesson) => lesson.topic == LessonTopic.links,
      );

      expect(bilingualIndex, greaterThanOrEqualTo(0));
      expect(linksIndex, bilingualIndex + 1);
    });
  });

  group('lesson content', () {
    test('dialogues omit speaker labels', () {
      final RegExp speakerLabel = RegExp(
        r'^[A-ZА-ЯЁ][A-Za-zА-Яа-яЁё]+: ',
        multiLine: true,
      );

      for (final TrainingCourse course in courses) {
        for (final TrainingLesson lesson in course.lessons) {
          expect(lesson.target, isNot(matches(speakerLabel)));
        }
      }
    });

    test('uses natural capitalization after Shift is introduced', () {
      final RegExp lowercaseAfterSentence = RegExp(r'[.!?] [a-zа-яё]');

      for (final TrainingCourse course in courses) {
        final int shiftLessonIndex = course.lessons.indexWhere(
          (TrainingLesson lesson) => lesson.skills.contains(LessonSkill.shift),
        );
        expect(shiftLessonIndex, greaterThanOrEqualTo(0));

        for (final TrainingLesson lesson
            in course.lessons.skip(shiftLessonIndex)) {
          expect(lesson.skills, contains(LessonSkill.shift));
          expect(lesson.target, isNot(matches(lowercaseAfterSentence)));
          for (final String line in lesson.target.split('\n')) {
            expect(line, matches(RegExp('^[A-ZА-ЯЁ]')));
          }
          if (course.language == CourseLanguage.english) {
            expect(lesson.target, isNot(matches(RegExp(r'\bi\b'))));
          }
        }
      }
    });
  });

  group('input requirements', () {
    test('every character is typeable and declared skills match its plan', () {
      for (final TrainingCourse course in courses) {
        for (final TrainingLesson lesson in course.lessons) {
          expect(
            _requiredSkills(course, lesson, engine),
            lesson.skills,
            reason: '${course.language.code}/${lesson.id} has stale skills',
          );
        }

        for (final LessonSkill skill in <LessonSkill>{
          LessonSkill.shift,
          LessonSkill.enter,
          LessonSkill.numbersAndSymbols,
        }) {
          expect(
            course.lessonsWithSkill(skill),
            isNotEmpty,
            reason: '${course.language.code} course must exercise $skill',
          );
        }
      }
    });

    test('English course never requires the Russian layout', () {
      final TrainingCourse course = courseFor(CourseLanguage.english);

      expect(course.lessonsWithSkill(LessonSkill.layoutSwitch), isEmpty);
      for (final TrainingLesson lesson in course.lessons) {
        expect(
          _requiredSkills(course, lesson, engine),
          isNot(contains(LessonSkill.layoutSwitch)),
          reason: '${lesson.id} requires another layout',
        );
      }
    });

    test('Russian bilingual lesson exercises both layouts', () {
      final TrainingCourse course = courseFor(CourseLanguage.russian);
      final TrainingLesson lesson = course.lessons.singleWhere(
        (TrainingLesson lesson) => lesson.topic == LessonTopic.bilingual,
      );

      expect(lesson.skills, contains(LessonSkill.layoutSwitch));
      expect(lesson.target, matches(RegExp('[a-z]')));
      expect(lesson.target, matches(RegExp('[а-яё]')));
      expect(_requiredSkills(course, lesson, engine), lesson.skills);
    });
  });
}

Set<LessonSkill> _requiredSkills(
  TrainingCourse course,
  TrainingLesson lesson,
  ChordEngine engine,
) {
  final Set<LessonSkill> result = <LessonSkill>{};
  CourseLanguage inputLanguage = course.language;

  for (final String character in lesson.target.split('')) {
    final List<ChordStep> steps = engine.planCharacter(
      target: character,
      inputLanguage: inputLanguage,
    );
    expect(
      steps,
      isNotEmpty,
      reason: '${course.language.code}/${lesson.id} cannot type "$character"',
    );

    for (final ChordStep step in steps) {
      if (step.switchTo != null) {
        result.add(LessonSkill.layoutSwitch);
        inputLanguage = step.switchTo!;
      }
      switch (step.modifier) {
        case ChordModifier.shift:
          result.add(LessonSkill.shift);
          break;
        case ChordModifier.numbersAndSymbols:
          result.add(LessonSkill.numbersAndSymbols);
          break;
        case null:
          break;
      }
      if (step.mask == enterChord) {
        result.add(LessonSkill.enter);
      }
    }
  }

  return result;
}
