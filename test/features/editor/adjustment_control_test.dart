import 'package:flutter/material.dart';
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

    testWidgets('emits sanitized adjustment values', (tester) async {
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

    testWidgets('shows positive values with a plus sign', (tester) async {
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
  });
}
