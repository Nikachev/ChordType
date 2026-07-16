import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chordtype/main.dart';

import 'test_support.dart';

void main() {
  testWidgets('lesson tiles clip ink painting inside the scrolling list', (
    WidgetTester tester,
  ) async {
    configureDesktopView(tester);

    await tester.pumpWidget(ChordtypeApp(storage: MemoryAppStorage()));
    await tester.pumpAndSettle();

    final Finder lessonTitle = find.text('Core chords II');
    final Finder lessonTile = find.ancestor(
      of: lessonTitle,
      matching: find.byType(InkWell),
    );
    final Finder courseList = find.ancestor(
      of: lessonTitle,
      matching: find.byType(ListView),
    );

    expect(lessonTile, findsOneWidget);
    expect(courseList, findsOneWidget);

    final BuildContext tileContext = tester.element(lessonTile);
    final Material? tileMaterial =
        tileContext.findAncestorWidgetOfExactType<Material>();

    expect(tileMaterial, isNotNull);
    expect(tileMaterial!.clipBehavior, Clip.antiAlias);

    await tester.drag(courseList, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
