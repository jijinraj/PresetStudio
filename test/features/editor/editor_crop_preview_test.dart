import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/crop_state.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/editor/domain/image_transform.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_crop_preview.dart';

void main() {
  testWidgets('default crop preserves the ordinary image renderer path', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: EditorCropPreview(
              sourceImagePath: 'missing-test-image.jpg',
              adjustments: ImageAdjustments.initial,
              transform: ImageTransform.initial,
              crop: CropState.initial,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('editor-crop-output-frame')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('editor-image-rotation')), findsOneWidget);
  });

  testWidgets('committed 3:2 crop keeps its output aspect ratio', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 700,
            child: Center(
              child: EditorCropPreview(
                sourceImagePath: 'missing-test-image.jpg',
                adjustments: ImageAdjustments.initial,
                transform: ImageTransform.initial,
                crop: const CropState(
                  aspectRatio: 3 / 2,
                  scale: 1.46,
                  offset: NormalizedCropOffset(dx: 0.08, dy: -0.04),
                ),
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );

    final frame = tester.widget<AspectRatio>(
      find.byKey(const ValueKey('editor-crop-output-frame')),
    );

    expect(frame.aspectRatio, closeTo(1.5, 0.000001));

    final scale = tester.widget<Transform>(
      find.byKey(const ValueKey('editor-crop-output-scale')),
    );

    expect(scale.transform.storage[0], greaterThan(1.46));

    final translation = tester.widget<Transform>(
      find.byKey(const ValueKey('editor-crop-output-translation')),
    );

    expect(translation.transform.storage[12], isNot(0));
    expect(translation.transform.storage[13], isNot(0));
  });

  testWidgets('committed preview combines ordinary rotation and straighten', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: Center(
              child: EditorCropPreview(
                sourceImagePath: 'missing-test-image.jpg',
                adjustments: ImageAdjustments.initial,
                transform: const ImageTransform(rotationDegrees: 90),
                crop: const CropState(aspectRatio: 1, straightenDegrees: 10),
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );

    final rotation = tester.widget<Transform>(
      find.byKey(const ValueKey('editor-crop-output-rotation')),
    );

    final expectedRadians = 100 * math.pi / 180;

    expect(
      rotation.transform.storage[0],
      closeTo(math.cos(expectedRadians), 0.000001),
    );
    expect(
      rotation.transform.storage[1],
      closeTo(math.sin(expectedRadians), 0.000001),
    );
  });
}
