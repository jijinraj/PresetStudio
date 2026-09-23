import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/editor/domain/image_transform.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_rendered_image.dart';

void main() {
  group('EditorRenderedImage', () {
    testWidgets('renders supplied quarter-turn rotation', (tester) async {
      for (final quarterTurns in <int>[0, 1, 2, 3]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EditorRenderedImage(
                sourceImagePath: 'missing-test-image.jpg',
                adjustments: ImageAdjustments.initial,
                transform: ImageTransform(rotationDegrees: quarterTurns * 90.0),
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        final rotatedBox = tester.widget<RotatedBox>(
          find.byKey(const ValueKey('editor-image-rotation')),
        );

        expect(rotatedBox.quarterTurns, quarterTurns);
      }
    });

    testWidgets('preserves color filtering while rotating', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorRenderedImage(
              sourceImagePath: 'missing-test-image.jpg',
              adjustments: const ImageAdjustments(exposure: 1.0),
              transform: const ImageTransform(rotationDegrees: 90.0),
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('editor-image-rotation')),
        findsOneWidget,
      );

      expect(find.byType(ColorFiltered), findsOneWidget);
    });
  });
}
