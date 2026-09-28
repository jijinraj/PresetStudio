import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_ruler_control.dart';
import 'package:presetstudio/theme/preset_studio_theme.dart';

void main() {
  testWidgets('ruler displays formatted value and paints fixed control', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: Scaffold(
          body: EditorRulerControl(
            value: 0.35,
            minValue: -5,
            maxValue: 5,
            defaultValue: 0,
            precisionStep: 0.01,
            interactionStep: 0.1,
            minorTickStep: 0.1,
            majorTickStep: 1,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('+0.35'), findsOneWidget);
    expect(find.byKey(const ValueKey('editor-ruler-painter')), findsOneWidget);
  });

  testWidgets('dragging ruler left increases value and clamps to range', (
    tester,
  ) async {
    var value = 0.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: EditorRulerControl(
                    value: value,
                    minValue: -1,
                    maxValue: 1,
                    defaultValue: 0,
                    precisionStep: 0.01,
                    interactionStep: 0.1,
                    minorTickStep: 0.1,
                    majorTickStep: 0.5,
                    pixelsPerMinorTick: 10,
                    onChanged: (next) {
                      setState(() {
                        value = next;
                      });
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    final surface = find.byKey(const ValueKey('editor-ruler-gesture-surface'));

    final center = tester.getCenter(surface);
    final gesture = await tester.startGesture(center);

    // Cross Flutter's drag touch-slop first. The measured movement below then
    // maps exactly to the ruler's configured pixels-per-tick scale.
    await gesture.moveBy(const Offset(-24, 0));
    await tester.pump();
    final valueAfterTouchSlop = value;

    await gesture.moveBy(const Offset(-50, 0));
    await tester.pump();
    expect(value - valueAfterTouchSlop, closeTo(0.5, 0.001));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.drag(surface, const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 50));
    expect(value, 1);
  });

  testWidgets('double tap resets to default value', (tester) async {
    var value = 0.72;
    var starts = 0;
    var ends = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: EditorRulerControl(
                value: value,
                minValue: -5,
                maxValue: 5,
                defaultValue: 0,
                precisionStep: 0.01,
                interactionStep: 0.1,
                minorTickStep: 0.1,
                majorTickStep: 1,
                onInteractionStart: () {
                  starts += 1;
                },
                onInteractionEnd: () {
                  ends += 1;
                },
                onChanged: (next) {
                  setState(() {
                    value = next;
                  });
                },
              ),
            );
          },
        ),
      ),
    );

    final surface = find.byKey(const ValueKey('editor-ruler-gesture-surface'));
    final detector = tester.widget<GestureDetector>(surface);

    detector.onDoubleTap!.call();
    await tester.pump();

    expect(value, 0);
    expect(starts, 1);
    expect(ends, 1);
  });

  testWidgets('semantics exposes configured interaction step', (tester) async {
    final semanticsHandle = tester.ensureSemantics();

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: PresetStudioTheme.dark,
          home: Scaffold(
            body: EditorRulerControl(
              value: 0,
              minValue: -5,
              maxValue: 5,
              defaultValue: 0,
              precisionStep: 0.01,
              interactionStep: 0.1,
              minorTickStep: 0.1,
              majorTickStep: 1,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final data = tester
          .getSemantics(find.byType(EditorRulerControl))
          .getSemanticsData();

      expect(data.value, '0.00');
      expect(data.increasedValue, '+0.10');
      expect(data.decreasedValue, '-0.10');
      expect(data.hasAction(SemanticsAction.increase), isTrue);
      expect(data.hasAction(SemanticsAction.decrease), isTrue);
    } finally {
      semanticsHandle.dispose();
    }
  });
}
