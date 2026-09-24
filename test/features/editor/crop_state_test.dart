import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/crop_state.dart';

void main() {
  group('CropState', () {
    test('starts as a full-frame free crop', () {
      const crop = CropState.initial;

      expect(crop.normalizedRect, NormalizedCropRect.fullFrame);
      expect(crop.aspectRatio, isNull);
      expect(crop.straightenDegrees, 0);
      expect(crop.scale, 1);
      expect(crop.offset, NormalizedCropOffset.zero);
      expect(crop.isDefault, isTrue);
    });

    test('stores non-destructive crop geometry', () {
      const crop = CropState(
        normalizedRect: NormalizedCropRect(
          left: 0.1,
          top: 0.2,
          right: 0.9,
          bottom: 0.8,
        ),
        aspectRatio: 4 / 5,
        straightenDegrees: 1.4,
        scale: 1.2,
        offset: NormalizedCropOffset(dx: 0.08, dy: -0.04),
      );

      expect(crop.normalizedRect.width, closeTo(0.8, 0.000001));
      expect(crop.normalizedRect.height, closeTo(0.6, 0.000001));
      expect(crop.aspectRatio, closeTo(0.8, 0.000001));
      expect(crop.straightenDegrees, closeTo(1.4, 0.000001));
      expect(crop.scale, closeTo(1.2, 0.000001));
      expect(crop.offset.dx, closeTo(0.08, 0.000001));
      expect(crop.offset.dy, closeTo(-0.04, 0.000001));
      expect(crop.isDefault, isFalse);
    });

    test('sanitizes invalid crop geometry', () {
      const crop = CropState(
        normalizedRect: NormalizedCropRect(
          left: 1.2,
          top: 0.8,
          right: -0.4,
          bottom: 0.8,
        ),
        aspectRatio: -1,
        straightenDegrees: 90,
        scale: 0.2,
        offset: NormalizedCropOffset(dx: double.nan, dy: double.infinity),
      );

      final sanitized = crop.sanitized();

      expect(sanitized.normalizedRect.left, 0);
      expect(sanitized.normalizedRect.right, 1);
      expect(
        sanitized.normalizedRect.height,
        greaterThanOrEqualTo(NormalizedCropRect.minimumExtent),
      );
      expect(sanitized.aspectRatio, isNull);
      expect(sanitized.straightenDegrees, CropState.maximumStraightenDegrees);
      expect(sanitized.scale, CropState.minimumScale);
      expect(sanitized.offset, NormalizedCropOffset.zero);
    });

    test('copyWith can return to Free aspect ratio', () {
      const crop = CropState(aspectRatio: 4 / 5);

      final free = crop.copyWith(clearAspectRatio: true);

      expect(free.aspectRatio, isNull);
    });
  });
}
