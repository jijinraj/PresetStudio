import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/image_transform.dart';

void main() {
  group('ImageTransform', () {
    test('starts in default state', () {
      const transform = ImageTransform.initial;

      expect(transform.rotationQuarterTurns, 0);

      expect(transform.flipHorizontal, isFalse);

      expect(transform.flipVertical, isFalse);

      expect(transform.isDefault, isTrue);
    });

    test('rotates clockwise through quarter turns', () {
      const initial = ImageTransform.initial;

      final first = initial.rotateClockwise();

      final second = first.rotateClockwise();

      final third = second.rotateClockwise();

      final fourth = third.rotateClockwise();

      expect(first.rotationQuarterTurns, 1);

      expect(second.rotationQuarterTurns, 2);

      expect(third.rotationQuarterTurns, 3);

      expect(fourth.rotationQuarterTurns, 0);
    });

    test('rotates counter clockwise through quarter turns', () {
      const initial = ImageTransform.initial;

      final rotated = initial.rotateCounterClockwise();

      expect(rotated.rotationQuarterTurns, 3);
    });

    test('normalizes arbitrary quarter turns', () {
      const initial = ImageTransform.initial;

      expect(initial.copyWith(rotationQuarterTurns: 5).rotationQuarterTurns, 1);

      expect(
        initial.copyWith(rotationQuarterTurns: -1).rotationQuarterTurns,
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
        rotationQuarterTurns: 2,
        flipHorizontal: true,
      );

      final updated = transform.copyWith(flipVertical: true);

      expect(updated.rotationQuarterTurns, 2);

      expect(updated.flipHorizontal, isTrue);

      expect(updated.flipVertical, isTrue);
    });
  });
}
