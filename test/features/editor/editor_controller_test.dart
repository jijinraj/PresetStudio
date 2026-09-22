import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';

void main() {
  group('EditorController', () {
    test('starts with an empty editor session', () {
      final controller = EditorController();

      expect(controller.session.hasImage, isFalse);
      expect(controller.session.isDirty, isFalse);
    });

    test('sets a source image', () {
      final controller = EditorController();

      controller.setSourceImage('photo.jpg');

      expect(controller.session.sourceImagePath, 'photo.jpg');
      expect(controller.session.hasImage, isTrue);
      expect(controller.session.isDirty, isFalse);
    });

    test('updating adjustments marks session dirty', () {
      final controller = EditorController();

      controller.updateAdjustments(const ImageAdjustments(exposure: 0.5));

      expect(controller.session.adjustments.exposure, 0.5);
      expect(controller.session.isDirty, isTrue);
    });

    test('manual adjustment clears active preset', () {
      final controller = EditorController();

      controller.applyPreset(
        presetId: 'preset-001',
        adjustments: const ImageAdjustments(contrast: 10),
      );

      expect(controller.session.activePresetId, 'preset-001');

      controller.updateAdjustments(const ImageAdjustments(contrast: 12));

      expect(controller.session.activePresetId, isNull);
    });

    test('clear source image resets the session', () {
      final controller = EditorController();

      controller.setSourceImage('photo.jpg');

      controller.updateAdjustments(const ImageAdjustments(saturation: 15));

      controller.clearSourceImage();

      expect(controller.session.hasImage, isFalse);
      expect(controller.session.adjustments.saturation, 0);
      expect(controller.session.isDirty, isFalse);
    });

    test('setting a new source image resets editing state', () {
      final controller = EditorController();

      controller.setSourceImage('first.jpg');

      controller.updateAdjustments(
        const ImageAdjustments(exposure: 1, saturation: 20),
      );

      controller.setSourceImage('second.jpg');

      expect(controller.session.sourceImagePath, 'second.jpg');
      expect(controller.session.adjustments.exposure, 0);
      expect(controller.session.adjustments.saturation, 0);
      expect(controller.session.activePresetId, isNull);
      expect(controller.session.isDirty, isFalse);
    });
  });
}
