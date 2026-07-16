import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chordtype/main.dart';

import 'test_support.dart';

void main() {
  testWidgets('keyboard fits when the wide practice panel becomes narrow', (
    WidgetTester tester,
  ) async {
    configureDesktopView(tester);

    await tester.pumpWidget(ChordtypeApp(storage: MemoryAppStorage()));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(1024, 720);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 45));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final Finder keyboard = find.byKey(
      const ValueKey<String>('chord-keyboard-row'),
    );
    final Finder keyCaps = find.descendant(
      of: keyboard,
      matching: find.byWidgetPredicate((Widget widget) {
        final Key? key = widget.key;
        return widget is SizedBox &&
            key is ValueKey<String> &&
            key.value.startsWith('chord-key-size-');
      }),
    );

    final Finder thumbGroup = find.byKey(
      const ValueKey<String>('chord-thumb-group'),
    );
    final Finder thumbRow = find.byKey(
      const ValueKey<String>('chord-thumb-row'),
    );
    final Finder firstThumb = find.byKey(
      const ValueKey<String>('chord-key-size-16'),
    );
    final Finder secondThumb = find.byKey(
      const ValueKey<String>('chord-key-size-32'),
    );
    final Finder indexKey = find.byKey(
      const ValueKey<String>('chord-key-size-8'),
    );

    expect(keyboard, findsOneWidget);
    expect(keyCaps, findsNWidgets(6));
    expect(thumbGroup, findsOneWidget);
    expect(thumbRow, findsOneWidget);
    expect(find.descendant(of: thumbGroup, matching: find.text('Thumb')),
        findsOneWidget);
    expect(
      find.descendant(
        of: thumbGroup,
        matching: find.byIcon(Icons.pan_tool_alt_rounded),
      ),
      findsNothing,
    );
    expect(
      tester.getCenter(firstThumb).dy,
      closeTo(tester.getCenter(secondThumb).dy, 0.1),
    );
    expect(
      tester.getCenter(firstThumb).dx,
      lessThan(tester.getCenter(secondThumb).dx),
    );
    expect(
      tester.getTopLeft(firstThumb).dy,
      greaterThan(tester.getBottomLeft(indexKey).dy),
    );
    expect(
      tester.getTopRight(thumbGroup).dx,
      closeTo(tester.getTopRight(keyboard).dx, 0.1),
    );
  });

  testWidgets('right-hand keys and thumb group mirror the left-hand layout', (
    WidgetTester tester,
  ) async {
    configureDesktopView(tester);
    await tester.pumpWidget(ChordtypeApp(storage: MemoryAppStorage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Right'));
    await tester.pumpAndSettle();

    final Finder keyboard = find.byKey(
      const ValueKey<String>('chord-keyboard-row'),
    );
    final Finder thumbGroup = find.byKey(
      const ValueKey<String>('chord-thumb-group'),
    );
    final Finder indexKey = find.byKey(
      const ValueKey<String>('chord-key-size-8'),
    );
    final Finder middleKey = find.byKey(
      const ValueKey<String>('chord-key-size-4'),
    );
    final Finder ringKey = find.byKey(
      const ValueKey<String>('chord-key-size-2'),
    );
    final Finder pinkyKey = find.byKey(
      const ValueKey<String>('chord-key-size-1'),
    );

    final List<double> fingerCenters = <double>[
      tester.getCenter(indexKey).dx,
      tester.getCenter(middleKey).dx,
      tester.getCenter(ringKey).dx,
      tester.getCenter(pinkyKey).dx,
    ];
    for (int index = 1; index < fingerCenters.length; index += 1) {
      expect(fingerCenters[index], greaterThan(fingerCenters[index - 1]));
    }
    expect(
      tester.getTopLeft(thumbGroup).dx,
      closeTo(tester.getTopLeft(keyboard).dx, 0.1),
    );
    for (final String label in <String>['U', 'I', 'O', 'P', 'B', 'N']) {
      expect(
        find.descendant(of: keyboard, matching: find.text(label)),
        findsOneWidget,
      );
    }
    for (final String role in <String>['index', 'middle', 'ring', 'pinky']) {
      expect(
        find.descendant(of: keyboard, matching: find.text(role)),
        findsOneWidget,
      );
    }
    expect(find.descendant(of: keyboard, matching: find.text('mid')),
        findsNothing);
  });
}
