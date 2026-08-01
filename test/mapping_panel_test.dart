import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chordtype/main.dart';

import 'test_support.dart';

void main() {
  testWidgets('dark mapping table is compact and keeps outputs high contrast', (
    WidgetTester tester,
  ) async {
    configureDesktopView(tester);
    final MemoryAppStorage storage = MemoryAppStorage(<String, String>{
      testStorageKey: appStateJson(darkMode: true),
    });

    await tester.pumpWidget(ChordtypeApp(storage: storage));
    await tester.pumpAndSettle();

    final Finder mappingList = find.byKey(
      const ValueKey<String>('mapping-list-base'),
    );
    final Finder mappingFrame = find.byKey(
      const ValueKey<String>('mapping-base-frame'),
    );
    final Finder outputCell = find.byKey(
      const ValueKey<String>('mapping-base-output-e'),
    );
    final Finder outputText = find.descendant(
      of: outputCell,
      matching: find.text('e'),
    );
    final Finder outputRow = find.byKey(
      const ValueKey<String>('mapping-base-row-e'),
    );

    expect(mappingList, findsOneWidget);
    expect(mappingFrame, findsOneWidget);
    expect(outputCell, findsOneWidget);
    expect(outputText, findsOneWidget);
    expect(find.descendant(of: mappingList, matching: find.text('Output')),
        findsOneWidget);
    expect(find.descendant(of: mappingList, matching: find.text('Chord')),
        findsOneWidget);

    final ColorScheme colors =
        Theme.of(tester.element(mappingList)).colorScheme;
    final Container frame = tester.widget<Container>(mappingFrame);
    final BoxDecoration frameBackground = frame.decoration! as BoxDecoration;
    final BoxDecoration frameForeground =
        frame.foregroundDecoration! as BoxDecoration;
    final ColoredBox cell = tester.widget<ColoredBox>(outputCell);
    final Text symbol = tester.widget<Text>(outputText);

    expect(cell.color, colors.primary);
    expect(frame.clipBehavior, Clip.antiAlias);
    expect(frameBackground.border, isNull);
    expect(frameForeground.border, isNotNull);
    expect(frameBackground.borderRadius, frameForeground.borderRadius);
    expect(symbol.style?.color, colors.onPrimary);
    expect(symbol.style?.fontFamily, 'monospace');
    expect(symbol.style?.fontSize, 18);
    expect(
      _contrastRatio(colors.primary, colors.onPrimary),
      greaterThanOrEqualTo(7),
    );
    expect(tester.getSize(outputRow).height, 42);
  });

  testWidgets('mapping panel separates base pairs from direct symbols', (
    WidgetTester tester,
  ) async {
    configureDesktopView(tester);
    await tester.pumpWidget(ChordtypeApp(storage: MemoryAppStorage()));
    await tester.pumpAndSettle();

    final Finder baseList = find.byKey(
      const ValueKey<String>('mapping-list-base'),
    );
    await tester.drag(baseList, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('mapping-base-output-. / +')),
      findsOneWidget,
    );
    expect(find.text('Numbers & symbols'), findsOneWidget);

    await tester.tap(find.text('Numbers & symbols'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>('mapping-list-numbers-symbols'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('mapping-numbers-symbols-output-{'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('mapping-numbers-symbols-output-}'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('mapping-numbers-symbols-output-{ / }'),
      ),
      findsNothing,
    );
    expect(find.text('Symbols'), findsNothing);
    expect(find.text('Numbers'), findsNothing);
  });
}

double _contrastRatio(Color first, Color second) {
  final double lighter = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final double darker = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}
