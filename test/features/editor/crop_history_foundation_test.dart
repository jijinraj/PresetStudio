import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/application/editor_history_entry.dart';
import 'package:presetstudio/features/editor/domain/crop_state.dart';

void main() {
  group('Crop History foundation', () {
    test('compound crop geometry becomes one replayable History operation', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');

      controller.beginSemanticEditTransaction(
        label: 'Crop · 4:5',
        action: EditorHistoryAction.crop,
      );

      controller.updateCrop(
        const CropState(
          normalizedRect: NormalizedCropRect(
            left: 0.1,
            top: 0.05,
            right: 0.9,
            bottom: 0.95,
          ),
          aspectRatio: 4 / 5,
          scale: 1.1,
        ),
      );

      controller.updateCrop(
        const CropState(
          normalizedRect: NormalizedCropRect(
            left: 0.12,
            top: 0.08,
            right: 0.88,
            bottom: 0.92,
          ),
          aspectRatio: 4 / 5,
          straightenDegrees: 1.4,
          scale: 1.18,
          offset: NormalizedCropOffset(dx: 0.04, dy: -0.02),
        ),
      );

      expect(controller.history, hasLength(1));

      controller.endEditTransaction();

      expect(controller.history, hasLength(2));
      expect(controller.history.last.label, 'Crop · 4:5');
      expect(controller.history.last.action, EditorHistoryAction.crop);
      expect(controller.session.crop.straightenDegrees, 1.4);
      expect(controller.session.crop.scale, 1.18);
      expect(controller.session.crop.offset.dx, 0.04);

      controller.setHistoryEntryEnabled(1, false);

      expect(controller.session.crop, CropState.initial);

      controller.setHistoryEntryEnabled(1, true);

      expect(
        controller.session.crop.normalizedRect,
        const NormalizedCropRect(
          left: 0.12,
          top: 0.08,
          right: 0.88,
          bottom: 0.92,
        ),
      );
      expect(controller.session.crop.aspectRatio, 4 / 5);
      expect(controller.session.crop.straightenDegrees, 1.4);
      expect(controller.session.crop.scale, 1.18);
      expect(
        controller.session.crop.offset,
        const NormalizedCropOffset(dx: 0.04, dy: -0.02),
      );
    });

    test('cancelled crop transaction restores exact crop state', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');

      const startingCrop = CropState(
        normalizedRect: NormalizedCropRect(
          left: 0.05,
          top: 0.1,
          right: 0.95,
          bottom: 0.9,
        ),
        aspectRatio: 3 / 2,
      );

      controller.updateCrop(startingCrop);

      final historyLength = controller.history.length;

      controller.beginSemanticEditTransaction(
        label: 'Straighten +2.0°',
        action: EditorHistoryAction.crop,
      );

      controller.updateCrop(
        startingCrop.copyWith(
          straightenDegrees: 2,
          scale: 1.08,
          offset: const NormalizedCropOffset(dx: 0.02, dy: 0.01),
        ),
      );

      controller.cancelEditTransaction();

      expect(controller.history, hasLength(historyLength));
      expect(controller.session.crop, startingCrop);
    });

    test('crop update is sanitized before entering the session', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');

      controller.updateCrop(
        const CropState(aspectRatio: -5, straightenDegrees: 200, scale: 0),
      );

      expect(controller.session.crop.aspectRatio, isNull);
      expect(
        controller.session.crop.straightenDegrees,
        CropState.maximumStraightenDegrees,
      );
      expect(controller.session.crop.scale, CropState.minimumScale);
    });
  });
}
