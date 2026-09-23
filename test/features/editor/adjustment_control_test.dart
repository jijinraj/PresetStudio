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

    testWidgets('displays adjustment label and default value', (tester) async {
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

      expect(find.text('0.0'), findsOneWidget);

      expect(find.text('-5.0'), findsOneWidget);

      expect(find.text('+5.0'), findsOneWidget);
    });

    testWidgets('configures slider from adjustment definition', (tester) async {
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
      expect(slider.divisions, 100);
    });

    testWidgets('emits sanitized slider values', (tester) async {
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

      slider.onChanged?.call(1.24);

      expect(changedValue, 1.2);
    });

    testWidgets('shows positive values with plus sign', (tester) async {
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

      expect(find.text('+1.5'), findsOneWidget);
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

    testWidgets('mouse wheel increases adjustment while over slider', (
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

    testWidgets('mouse wheel decreases adjustment while over slider', (
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

    testWidgets('arrow up increases focused slider', (tester) async {
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

    testWidgets('arrow down decreases focused slider', (tester) async {
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

      await tester.enterText(input, '1.7');

      await tester.testTextInput.receiveAction(TextInputAction.done);

      await tester.pump();

      expect(changedValue, 1.7);
    });

    testWidgets('sanitizes manually entered values', (tester) async {
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

      expect(changedValue, 1.3);
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

      await tester.enterText(input, '-2.0');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);

      await tester.pump();

      expect(changedValue, isNull);
      expect(find.text('+1.5'), findsOneWidget);
    });
  });
}
