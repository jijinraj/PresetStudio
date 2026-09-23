import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/image_transform.dart';
import 'package:presetstudio/features/editor/presentation/widgets/rotation_control.dart';

void main() {
  group('RotationControl', () {
    testWidgets('displays degree range and default value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RotationControl(
              transform: ImageTransform.initial,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Rotation'), findsOneWidget);

      expect(find.text('0.0°'), findsOneWidget);

      expect(find.text('-180.0°'), findsOneWidget);

      expect(find.text('+180.0°'), findsOneWidget);
    });

    testWidgets('rotates left by ninety degrees', (tester) async {
      ImageTransform? changedTransform;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RotationControl(
              transform: ImageTransform.initial,
              onChanged: (transform) {
                changedTransform = transform;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('rotation-left-90')));

      expect(changedTransform?.rotationDegrees, -90.0);
    });

    testWidgets('rotates right by ninety degrees', (tester) async {
      ImageTransform? changedTransform;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RotationControl(
              transform: ImageTransform.initial,
              onChanged: (transform) {
                changedTransform = transform;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('rotation-right-90')));

      expect(changedTransform?.rotationDegrees, 90.0);
    });

    testWidgets('sanitizes slider values to tenth-degree precision', (
      tester,
    ) async {
      ImageTransform? changedTransform;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RotationControl(
              transform: ImageTransform.initial,
              onChanged: (transform) {
                changedTransform = transform;
              },
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('rotation-slider')),
      );

      slider.onChanged?.call(13.74);

      expect(changedTransform?.rotationDegrees, 13.7);
    });

    testWidgets('clamps rotation to supported slider range', (tester) async {
      ImageTransform? changedTransform;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RotationControl(
              transform: ImageTransform.initial,
              onChanged: (transform) {
                changedTransform = transform;
              },
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('rotation-slider')),
      );

      slider.onChanged?.call(500.0);

      expect(changedTransform?.rotationDegrees, 180.0);
    });
  });
}
