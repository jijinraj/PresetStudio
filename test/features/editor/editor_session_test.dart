import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/editor_session.dart';
import 'package:presetstudio/features/editor/domain/image_transform.dart';

void main() {
  group('EditorSession', () {
    test('starts with expected initial state', () {
      const session = EditorSession.initial;

      expect(session.sourceImagePath, isNull);
      expect(session.hasImage, isFalse);
      expect(session.activePresetId, isNull);
      expect(session.isDirty, isFalse);

      expect(session.adjustments.exposure, 0);
      expect(session.adjustments.contrast, 0);
      expect(session.adjustments.saturation, 0);
      expect(session.transform.isDefault, isTrue);
    });

    test('copyWith preserves unchanged values', () {
      const session = EditorSession(
        sourceImagePath: 'photo.jpg',
        isDirty: false,
      );

      final updated = session.copyWith(isDirty: true);

      expect(updated.sourceImagePath, 'photo.jpg');
      expect(updated.hasImage, isTrue);
      expect(updated.isDirty, isTrue);
    });

    test('can clear nullable session values', () {
      const session = EditorSession(
        sourceImagePath: 'photo.jpg',
        activePresetId: 'preset-001',
      );

      final updated = session.copyWith(
        clearSourceImage: true,
        clearActivePreset: true,
      );

      expect(updated.sourceImagePath, isNull);
      expect(updated.activePresetId, isNull);
    });

    test('copyWith updates image transform state', () {
      const session = EditorSession.initial;

      const transform = ImageTransform(
        rotationQuarterTurns: 1,
        flipHorizontal: true,
      );

      final updated = session.copyWith(transform: transform);

      expect(updated.transform.rotationQuarterTurns, 1);

      expect(updated.transform.flipHorizontal, isTrue);

      expect(updated.transform.flipVertical, isFalse);
    });
  });
}
