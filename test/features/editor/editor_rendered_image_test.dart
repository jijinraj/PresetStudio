import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/editor/domain/image_transform.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_rendered_image.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_rotation_layout.dart';

void main() {
  group('EditorRenderedImage', () {
    testWidgets('renders exact arbitrary rotation angles', (tester) async {
      for (final degrees in <double>[0.0, 13.7, 45.0, 90.0, -27.4, 180.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EditorRenderedImage(
                sourceImagePath: 'missing-test-image.jpg',
                adjustments: ImageAdjustments.initial,
                transform: ImageTransform(rotationDegrees: degrees),
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        final rotation = tester.widget<EditorRotationLayout>(
          find.byKey(const ValueKey('editor-image-rotation')),
        );

        expect(rotation.rotationDegrees, closeTo(degrees, 0.000001));
      }
    });

    testWidgets('renders horizontal flip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorRenderedImage(
              sourceImagePath: 'missing-test-image.jpg',
              adjustments: ImageAdjustments.initial,
              transform: const ImageTransform(flipHorizontal: true),
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final flip = tester.widget<Transform>(
        find.byKey(const ValueKey('editor-image-flip')),
      );

      expect(flip.transform.storage[0], -1.0);

      expect(flip.transform.storage[5], 1.0);
    });

    testWidgets('renders vertical flip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorRenderedImage(
              sourceImagePath: 'missing-test-image.jpg',
              adjustments: ImageAdjustments.initial,
              transform: const ImageTransform(flipVertical: true),
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final flip = tester.widget<Transform>(
        find.byKey(const ValueKey('editor-image-flip')),
      );

      expect(flip.transform.storage[0], 1.0);

      expect(flip.transform.storage[5], -1.0);
    });

    testWidgets('renders horizontal and vertical flip together', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorRenderedImage(
              sourceImagePath: 'missing-test-image.jpg',
              adjustments: ImageAdjustments.initial,
              transform: const ImageTransform(
                flipHorizontal: true,
                flipVertical: true,
              ),
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final flip = tester.widget<Transform>(
        find.byKey(const ValueKey('editor-image-flip')),
      );

      expect(flip.transform.storage[0], -1.0);

      expect(flip.transform.storage[5], -1.0);
    });

    testWidgets('uses identity flip transform by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorRenderedImage(
              sourceImagePath: 'missing-test-image.jpg',
              adjustments: ImageAdjustments.initial,
              transform: ImageTransform.initial,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final flip = tester.widget<Transform>(
        find.byKey(const ValueKey('editor-image-flip')),
      );

      expect(flip.transform.storage[0], 1.0);

      expect(flip.transform.storage[5], 1.0);
    });

    testWidgets('combines rotation flips and color filtering', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorRenderedImage(
              sourceImagePath: 'missing-test-image.jpg',
              adjustments: const ImageAdjustments(exposure: 1.0),
              transform: const ImageTransform(
                rotationDegrees: 13.7,
                flipHorizontal: true,
                flipVertical: true,
              ),
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final rotation = tester.widget<EditorRotationLayout>(
        find.byKey(const ValueKey('editor-image-rotation')),
      );

      final flip = tester.widget<Transform>(
        find.byKey(const ValueKey('editor-image-flip')),
      );

      expect(rotation.rotationDegrees, closeTo(13.7, 0.000001));

      expect(flip.transform.storage[0], -1.0);

      expect(flip.transform.storage[5], -1.0);

      expect(find.byKey(const ValueKey('editor-color-filter')), findsOneWidget);
    });
    testWidgets('accepts temperature tint and vibrance in the color stage', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorRenderedImage(
              sourceImagePath: 'missing-test-image.jpg',
              adjustments: const ImageAdjustments(
                temperature: 35,
                tint: -20,
                vibrance: 45,
              ),
              transform: ImageTransform.initial,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('editor-color-filter')), findsOneWidget);
    });

    testWidgets('accepts tonal range adjustments in the color stage', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorRenderedImage(
              sourceImagePath: 'missing-test-image.jpg',
              adjustments: const ImageAdjustments(
                highlights: 35,
                shadows: -25,
                whites: 20,
                blacks: -15,
              ),
              transform: ImageTransform.initial,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('editor-color-filter')), findsOneWidget);
    });
  });
}
