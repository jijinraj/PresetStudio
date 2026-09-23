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

    testWidgets('preserves color filtering while rotating', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorRenderedImage(
              sourceImagePath: 'missing-test-image.jpg',
              adjustments: const ImageAdjustments(exposure: 1.0),
              transform: const ImageTransform(rotationDegrees: 13.7),
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(find.byType(EditorRotationLayout), findsOneWidget);

      expect(find.byType(ColorFiltered), findsOneWidget);
    });
  });
}
