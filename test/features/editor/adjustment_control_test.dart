import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/adjustment_definition.dart';
import 'package:presetstudio/features/editor/domain/adjustment_type.dart';
import 'package:presetstudio/features/editor/presentation/widgets/adjustment_control.dart';

void main() {
  group('AdjustmentControl', () {
    final exposureDefinition = AdjustmentDefinitions.of(
      AdjustmentType.exposure,
    );

    testWidgets('displays adjustment label and precise default value', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Exposure'), findsOneWidget);

      expect(find.text('0.00'), findsOneWidget);

      expect(find.text('-5.00'), findsOneWidget);

      expect(find.text('+5.00'), findsOneWidget);
    });

    testWidgets('configures slider from interaction step', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('adjustment-exposure-slider')),
      );

      expect(slider.value, 0.0);
      expect(slider.min, -5.0);
      expect(slider.max, 5.0);

      // -5 to +5 using 0.1 interaction increments.
      expect(slider.divisions, 100);
    });

    testWidgets('sanitizes emitted values to precision step', (tester) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('adjustment-exposure-slider')),
      );

      slider.onChanged?.call(1.237);

      expect(changedValue, 1.24);
    });

    testWidgets('shows positive values with plus sign and precision', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 1.5,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('+1.50'), findsOneWidget);
    });

    testWidgets('shows reset action for non-default values', (tester) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 1.5,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      final resetButton = find.byKey(
        const ValueKey('adjustment-exposure-reset'),
      );

      expect(resetButton, findsOneWidget);

      await tester.tap(resetButton);
      await tester.pump();

      expect(changedValue, exposureDefinition.defaultValue);
    });

    testWidgets('hides reset action at default value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('adjustment-exposure-reset')),
        findsNothing,
      );
    });

    testWidgets('disables slider interaction when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (_) {},
              enabled: false,
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('adjustment-exposure-slider')),
      );

      expect(slider.onChanged, isNull);
    });

    testWidgets('mouse wheel increases by normal interaction step', (
      tester,
    ) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      final interaction = tester.widget<Listener>(
        find.byKey(const ValueKey('adjustment-exposure-slider-interaction')),
      );

      interaction.onPointerSignal?.call(
        const PointerScrollEvent(scrollDelta: Offset(0, -20)),
      );

      expect(changedValue, 0.1);
    });

    testWidgets('mouse wheel decreases by normal interaction step', (
      tester,
    ) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      final interaction = tester.widget<Listener>(
        find.byKey(const ValueKey('adjustment-exposure-slider-interaction')),
      );

      interaction.onPointerSignal?.call(
        const PointerScrollEvent(scrollDelta: Offset(0, 20)),
      );

      expect(changedValue, -0.1);
    });

    testWidgets('arrow up increases by normal interaction step', (
      tester,
    ) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('adjustment-exposure-slider')),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);

      expect(changedValue, 0.1);
    });

    testWidgets('arrow down decreases by normal interaction step', (
      tester,
    ) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('adjustment-exposure-slider')),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

      expect(changedValue, -0.1);
    });

    testWidgets('arrow right increases by normal interaction step', (
      tester,
    ) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('adjustment-exposure-slider')),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);

      expect(changedValue, 0.1);
    });

    testWidgets('arrow left decreases by normal interaction step', (
      tester,
    ) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('adjustment-exposure-slider')),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);

      expect(changedValue, -0.1);
    });

    testWidgets('allows direct numeric value entry', (tester) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('adjustment-exposure-value')));

      await tester.pump();

      final input = find.byKey(
        const ValueKey('adjustment-exposure-value-input'),
      );

      expect(input, findsOneWidget);

      await tester.enterText(input, '1.70');

      await tester.testTextInput.receiveAction(TextInputAction.done);

      await tester.pump();

      expect(changedValue, 1.7);
    });

    testWidgets('preserves hundredth precision in manually entered values', (
      tester,
    ) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('adjustment-exposure-value')));

      await tester.pump();

      final input = find.byKey(
        const ValueKey('adjustment-exposure-value-input'),
      );

      await tester.enterText(input, '1.27');

      await tester.testTextInput.receiveAction(TextInputAction.done);

      await tester.pump();

      expect(changedValue, 1.27);
    });

    testWidgets('rounds manual input to canonical precision', (tester) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('adjustment-exposure-value')));

      await tester.pump();

      final input = find.byKey(
        const ValueKey('adjustment-exposure-value-input'),
      );

      await tester.enterText(input, '1.276');

      await tester.testTextInput.receiveAction(TextInputAction.done);

      await tester.pump();

      expect(changedValue, 1.28);
    });

    testWidgets('clamps manually entered values to adjustment range', (
      tester,
    ) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 0.0,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('adjustment-exposure-value')));

      await tester.pump();

      final input = find.byKey(
        const ValueKey('adjustment-exposure-value-input'),
      );

      await tester.enterText(input, '99');

      await tester.testTextInput.receiveAction(TextInputAction.done);

      await tester.pump();

      expect(changedValue, 5.0);
    });

    testWidgets('escape cancels direct numeric editing', (tester) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 1.5,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('adjustment-exposure-value')));

      await tester.pump();

      final input = find.byKey(
        const ValueKey('adjustment-exposure-value-input'),
      );

      await tester.enterText(input, '-2.00');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);

      await tester.pump();

      expect(changedValue, isNull);

      expect(find.text('+1.50'), findsOneWidget);
    });
    testWidgets(
      'arrow up adjusts numeric editor without committing immediately',
      (tester) async {
        double? changedValue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdjustmentControl(
                definition: exposureDefinition,
                value: 1.27,
                onChanged: (value) {
                  changedValue = value;
                },
              ),
            ),
          ),
        );

        await tester.tap(
          find.byKey(const ValueKey('adjustment-exposure-value')),
        );

        await tester.pump();

        final input = find.byKey(
          const ValueKey('adjustment-exposure-value-input'),
        );

        expect(input, findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);

        await tester.pump();

        final textField = tester.widget<TextField>(input);

        expect(textField.controller?.text, '1.37');

        expect(changedValue, isNull);

        await tester.testTextInput.receiveAction(TextInputAction.done);

        await tester.pump();

        expect(changedValue, 1.37);
      },
    );

    testWidgets(
      'arrow down adjusts numeric editor without committing immediately',
      (tester) async {
        double? changedValue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdjustmentControl(
                definition: exposureDefinition,
                value: 1.27,
                onChanged: (value) {
                  changedValue = value;
                },
              ),
            ),
          ),
        );

        await tester.tap(
          find.byKey(const ValueKey('adjustment-exposure-value')),
        );

        await tester.pump();

        final input = find.byKey(
          const ValueKey('adjustment-exposure-value-input'),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

        await tester.pump();

        final textField = tester.widget<TextField>(input);

        expect(textField.controller?.text, '1.17');

        expect(changedValue, isNull);
      },
    );

    testWidgets('control plus arrow uses precision step in numeric editor', (
      tester,
    ) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 1.27,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('adjustment-exposure-value')));

      await tester.pump();

      final input = find.byKey(
        const ValueKey('adjustment-exposure-value-input'),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      await tester.pump();

      final textField = tester.widget<TextField>(input);

      expect(textField.controller?.text, '1.28');

      expect(changedValue, isNull);
    });

    testWidgets('control plus arrow uses precision step', (tester) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 1.27,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('adjustment-exposure-slider')),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(changedValue, 1.28);
    });

    testWidgets('shift plus arrow uses coarse step', (tester) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 1.27,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('adjustment-exposure-slider')),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      expect(changedValue, 1.77);
    });

    testWidgets('control plus mouse wheel uses precision step', (tester) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 1.27,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      final interaction = tester.widget<Listener>(
        find.byKey(const ValueKey('adjustment-exposure-slider-interaction')),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);

      interaction.onPointerSignal?.call(
        const PointerScrollEvent(scrollDelta: Offset(0, -20)),
      );

      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(changedValue, 1.28);
    });

    testWidgets('shift plus mouse wheel uses coarse step', (tester) async {
      double? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustmentControl(
              definition: exposureDefinition,
              value: 1.27,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      final interaction = tester.widget<Listener>(
        find.byKey(const ValueKey('adjustment-exposure-slider-interaction')),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);

      interaction.onPointerSignal?.call(
        const PointerScrollEvent(scrollDelta: Offset(0, -20)),
      );

      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      expect(changedValue, 1.77);
    });
  });
}
