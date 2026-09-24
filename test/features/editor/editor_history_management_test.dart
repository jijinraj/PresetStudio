import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/application/editor_history_entry.dart';
import 'package:presetstudio/features/editor/domain/adjustment_type.dart';

void main() {
  group('History edit toggles', () {
    test('disabling an earlier adjustment removes only its effect', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      controller.updateAdjustment(AdjustmentType.exposure, 1.0);
      controller.updateAdjustment(AdjustmentType.contrast, 20);
      controller.updateAdjustment(AdjustmentType.saturation, 30);

      controller.setHistoryEntryEnabled(1, false);

      expect(controller.history[1].isEnabled, isFalse);
      expect(controller.disabledHistoryCount, 1);
      expect(controller.session.adjustments.exposure, 0);
      expect(controller.session.adjustments.contrast, 20);
      expect(controller.session.adjustments.saturation, 30);

      controller.setHistoryEntryEnabled(1, true);

      expect(controller.history[1].isEnabled, isTrue);
      expect(controller.session.adjustments.exposure, 1.0);
      expect(controller.session.adjustments.contrast, 20);
      expect(controller.session.adjustments.saturation, 30);
    });

    test('later adjustment to same control remains authoritative', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      controller.updateAdjustment(AdjustmentType.exposure, 1.0);
      controller.updateAdjustment(AdjustmentType.contrast, 20);
      controller.updateAdjustment(AdjustmentType.exposure, 2.0);

      controller.setHistoryEntryEnabled(1, false);

      expect(controller.session.adjustments.exposure, 2.0);
      expect(controller.session.adjustments.contrast, 20);
    });

    test('disabling an earlier rotation preserves later relative rotation', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');

      controller.updateTransform(
        controller.session.transform.rotateClockwise(),
      );
      controller.updateTransform(
        controller.session.transform.rotateClockwise(),
      );

      expect(controller.session.transform.normalizedRotationDegrees, 180);

      controller.setHistoryEntryEnabled(1, false);

      expect(controller.session.transform.normalizedRotationDegrees, 90);
    });

    test('undo and redo replay enabled operations only', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      controller.updateAdjustment(AdjustmentType.exposure, 1.0);
      controller.updateAdjustment(AdjustmentType.contrast, 20);
      controller.updateAdjustment(AdjustmentType.saturation, 30);

      controller.setHistoryEntryEnabled(1, false);

      controller.undo();

      expect(controller.historyIndex, 2);
      expect(controller.session.adjustments.exposure, 0);
      expect(controller.session.adjustments.contrast, 20);
      expect(controller.session.adjustments.saturation, 0);

      controller.undo();

      expect(controller.historyIndex, 1);
      expect(controller.session.adjustments.exposure, 0);
      expect(controller.session.adjustments.contrast, 0);

      controller.redo();

      expect(controller.historyIndex, 2);
      expect(controller.session.adjustments.exposure, 0);
      expect(controller.session.adjustments.contrast, 20);
    });

    test(
      'enable all restores disabled edits through current history state',
      () {
        final controller = EditorController();
        addTearDown(controller.dispose);

        controller.setSourceImage('photo.jpg');
        controller.updateAdjustment(AdjustmentType.exposure, 1.0);
        controller.updateAdjustment(AdjustmentType.contrast, 20);
        controller.updateAdjustment(AdjustmentType.saturation, 30);

        controller.setHistoryEntryEnabled(1, false);
        controller.setHistoryEntryEnabled(2, false);

        expect(controller.disabledHistoryCount, 2);
        expect(controller.session.adjustments.exposure, 0);
        expect(controller.session.adjustments.contrast, 0);
        expect(controller.session.adjustments.saturation, 30);

        controller.enableAllHistoryEntries();

        expect(controller.disabledHistoryCount, 0);
        expect(controller.session.adjustments.exposure, 1.0);
        expect(controller.session.adjustments.contrast, 20);
        expect(controller.session.adjustments.saturation, 30);
      },
    );

    test('clear history keeps effective image state as checkpoint', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      controller.updateAdjustment(AdjustmentType.exposure, 1.0);
      controller.updateAdjustment(AdjustmentType.contrast, 20);
      controller.updateAdjustment(AdjustmentType.saturation, 30);

      controller.setHistoryEntryEnabled(1, false);

      controller.clearHistoryKeepingCurrent();

      expect(controller.history, hasLength(1));
      expect(controller.historyIndex, 0);
      expect(controller.history.single.label, 'Current state');
      expect(controller.history.single.action, EditorHistoryAction.checkpoint);
      expect(controller.session.adjustments.exposure, 0);
      expect(controller.session.adjustments.contrast, 20);
      expect(controller.session.adjustments.saturation, 30);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
    });
  });
}
