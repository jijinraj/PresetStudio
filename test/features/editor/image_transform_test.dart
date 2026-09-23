import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/image_transform.dart';

void main() {
  group('ImageTransform', () {
    test('starts in default state', () {
      const transform = ImageTransform.initial;

      expect(transform.rotationDegrees, 0.0);
      expect(transform.normalizedRotationDegrees, 0.0);

      expect(transform.flipHorizontal, isFalse);
      expect(transform.flipVertical, isFalse);
      expect(transform.isDefault, isTrue);
    });

    test('rotates clockwise through full rotation', () {
      const initial = ImageTransform.initial;

      final first = initial.rotateClockwise();
      final second = first.rotateClockwise();
      final third = second.rotateClockwise();
      final fourth = third.rotateClockwise();

      expect(first.rotationDegrees, 90.0);
      expect(second.rotationDegrees, 180.0);
      expect(third.rotationDegrees, -90.0);
      expect(fourth.rotationDegrees, 0.0);

      expect(fourth.isDefault, isTrue);
    });

    test('rotates counter clockwise by ninety degrees', () {
      const initial = ImageTransform.initial;

      final rotated = initial.rotateCounterClockwise();

      expect(rotated.rotationDegrees, -90.0);

      expect(rotated.rotationQuarterTurns, 3);
    });

    test('supports arbitrary rotation degrees', () {
      const initial = ImageTransform.initial;

      final rotated = initial.rotateBy(13.7);

      expect(rotated.rotationDegrees, closeTo(13.7, 0.000001));

      final updated = rotated.rotateBy(1.3);

      expect(updated.rotationDegrees, closeTo(15.0, 0.000001));
    });

    test('normalizes rotation degrees', () {
      const initial = ImageTransform.initial;

      expect(initial.copyWith(rotationDegrees: 450.0).rotationDegrees, 90.0);

      expect(initial.copyWith(rotationDegrees: -450.0).rotationDegrees, -90.0);

      expect(initial.copyWith(rotationDegrees: 360.0).rotationDegrees, 0.0);

      expect(initial.copyWith(rotationDegrees: 181.0).rotationDegrees, -179.0);

      expect(initial.copyWith(rotationDegrees: -181.0).rotationDegrees, 179.0);
    });

    test('derives quarter turns for existing renderer', () {
      expect(
        const ImageTransform(rotationDegrees: 0.0).rotationQuarterTurns,
        0,
      );

      expect(
        const ImageTransform(rotationDegrees: 90.0).rotationQuarterTurns,
        1,
      );

      expect(
        const ImageTransform(rotationDegrees: 180.0).rotationQuarterTurns,
        2,
      );

      expect(
        const ImageTransform(rotationDegrees: -90.0).rotationQuarterTurns,
        3,
      );
    });

    test('toggles horizontal flip', () {
      const initial = ImageTransform.initial;

      final flipped = initial.toggleFlipHorizontal();

      expect(flipped.flipHorizontal, isTrue);
      expect(flipped.flipVertical, isFalse);
      expect(flipped.isDefault, isFalse);

      expect(flipped.toggleFlipHorizontal().flipHorizontal, isFalse);
    });

    test('toggles vertical flip', () {
      const initial = ImageTransform.initial;

      final flipped = initial.toggleFlipVertical();

      expect(flipped.flipHorizontal, isFalse);
      expect(flipped.flipVertical, isTrue);
      expect(flipped.isDefault, isFalse);
    });

    test('copyWith preserves unchanged values', () {
      const transform = ImageTransform(
        rotationDegrees: 180.0,
        flipHorizontal: true,
      );

      final updated = transform.copyWith(flipVertical: true);

      expect(updated.rotationDegrees, 180.0);

      expect(updated.flipHorizontal, isTrue);

      expect(updated.flipVertical, isTrue);
    });
  });
}
