import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/image_transform.dart';
import 'package:presetstudio/features/editor/presentation/widgets/flip_control.dart';

void main() {
  group('FlipControl', () {
    testWidgets('shows horizontal and vertical controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlipControl(
              transform: ImageTransform.initial,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('flip-horizontal')), findsOneWidget);

      expect(find.byKey(const ValueKey('flip-vertical')), findsOneWidget);

      expect(find.text('Horizontal'), findsOneWidget);

      expect(find.text('Vertical'), findsOneWidget);
    });

    testWidgets(
      'toggles horizontal flip while preserving other transform state',
      (tester) async {
        ImageTransform? emitted;

        const initial = ImageTransform(
          rotationDegrees: 13.7,
          flipVertical: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlipControl(
                transform: initial,
                onChanged: (transform) {
                  emitted = transform;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('flip-horizontal')));

        expect(emitted, isNotNull);

        expect(emitted!.flipHorizontal, isTrue);

        expect(emitted!.flipVertical, isTrue);

        expect(emitted!.rotationDegrees, closeTo(13.7, 0.000001));
      },
    );

    testWidgets(
      'toggles vertical flip while preserving other transform state',
      (tester) async {
        ImageTransform? emitted;

        const initial = ImageTransform(
          rotationDegrees: -27.4,
          flipHorizontal: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlipControl(
                transform: initial,
                onChanged: (transform) {
                  emitted = transform;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('flip-vertical')));

        expect(emitted, isNotNull);

        expect(emitted!.flipHorizontal, isTrue);

        expect(emitted!.flipVertical, isTrue);

        expect(emitted!.rotationDegrees, closeTo(-27.4, 0.000001));
      },
    );

    testWidgets('active horizontal flip can be toggled off', (tester) async {
      ImageTransform? emitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlipControl(
              transform: const ImageTransform(flipHorizontal: true),
              onChanged: (transform) {
                emitted = transform;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('flip-horizontal')));

      expect(emitted!.flipHorizontal, isFalse);
    });

    testWidgets('disabled controls do not update transform', (tester) async {
      ImageTransform? emitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlipControl(
              transform: ImageTransform.initial,
              enabled: false,
              onChanged: (transform) {
                emitted = transform;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('flip-horizontal')));

      await tester.tap(find.byKey(const ValueKey('flip-vertical')));

      expect(emitted, isNull);
    });
  });
}
