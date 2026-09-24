import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/application/editor_history_entry.dart';
import 'package:presetstudio/features/editor/domain/adjustment_type.dart';

void main() {
  group('Editor history', () {
    test('loading image starts history at Original', () {
      final controller = EditorController();

      controller.setSourceImage('photo.jpg');

      expect(controller.history, hasLength(1));

      expect(controller.historyIndex, 0);

      expect(controller.history.first.label, 'Original');

      expect(controller.history.first.action, EditorHistoryAction.original);

      expect(controller.canUndo, isFalse);

      expect(controller.canRedo, isFalse);
    });

    test('adjustments create descriptive history entries', () {
      final controller = EditorController();

      controller.setSourceImage('photo.jpg');

      controller.updateAdjustment(AdjustmentType.exposure, 1.2);

      controller.updateAdjustment(AdjustmentType.contrast, 25);

      expect(controller.history, hasLength(3));

      expect(controller.history[1].label, 'Exposure +1.20');

      expect(controller.history[2].label, 'Contrast +25');

      expect(controller.historyIndex, 2);
    });

    test('undo and redo move through history', () {
      final controller = EditorController();

      controller.setSourceImage('photo.jpg');

      controller.updateAdjustment(AdjustmentType.exposure, 1.5);

      controller.updateAdjustment(AdjustmentType.saturation, 20);

      expect(controller.historyIndex, 2);

      controller.undo();

      expect(controller.historyIndex, 1);

      expect(controller.session.adjustments.exposure, 1.5);

      expect(controller.session.adjustments.saturation, 0);

      controller.undo();

      expect(controller.historyIndex, 0);

      expect(controller.session.adjustments.exposure, 0);

      controller.redo();

      expect(controller.historyIndex, 1);

      expect(controller.session.adjustments.exposure, 1.5);
    });

    test('continuous transaction creates one history entry', () {
      final controller = EditorController();

      controller.setSourceImage('photo.jpg');

      controller.beginEditTransaction();

      controller.updateAdjustment(AdjustmentType.exposure, 0.2);

      controller.updateAdjustment(AdjustmentType.exposure, 0.8);

      controller.updateAdjustment(AdjustmentType.exposure, 1.4);

      controller.updateAdjustment(AdjustmentType.exposure, 1.8);

      expect(controller.history, hasLength(1));

      controller.endEditTransaction();

      expect(controller.history, hasLength(2));

      expect(controller.history.last.label, 'Exposure +1.80');

      controller.undo();

      expect(controller.session.adjustments.exposure, 0);

      controller.redo();

      expect(controller.session.adjustments.exposure, 1.8);
    });

    test('empty transaction does not create history', () {
      final controller = EditorController();

      controller.setSourceImage('photo.jpg');

      controller.beginEditTransaction();
      controller.endEditTransaction();

      expect(controller.history, hasLength(1));

      expect(controller.canUndo, isFalse);
    });

    test('editing after undo discards future history', () {
      final controller = EditorController();

      controller.setSourceImage('photo.jpg');

      controller.updateAdjustment(AdjustmentType.exposure, 1);

      controller.updateAdjustment(AdjustmentType.contrast, 25);

      controller.undo();

      expect(controller.canRedo, isTrue);

      controller.updateAdjustment(AdjustmentType.saturation, -20);

      expect(controller.canRedo, isFalse);

      expect(controller.history, hasLength(3));

      expect(controller.history.last.label, 'Saturation -20');
    });

    test('can jump directly to history entry', () {
      final controller = EditorController();

      controller.setSourceImage('photo.jpg');

      controller.updateAdjustment(AdjustmentType.exposure, 1);

      controller.updateAdjustment(AdjustmentType.contrast, 30);

      controller.updateAdjustment(AdjustmentType.saturation, 40);

      controller.jumpToHistory(1);

      expect(controller.historyIndex, 1);

      expect(controller.session.adjustments.exposure, 1);

      expect(controller.session.adjustments.contrast, 0);

      expect(controller.session.adjustments.saturation, 0);

      expect(controller.canRedo, isTrue);
    });

    test('opening another image resets history', () {
      final controller = EditorController();

      controller.setSourceImage('first.jpg');

      controller.updateAdjustment(AdjustmentType.exposure, 1);

      controller.setSourceImage('second.jpg');

      expect(controller.history, hasLength(1));

      expect(controller.history.first.label, 'Original');

      expect(controller.session.sourceImagePath, 'second.jpg');

      expect(controller.canUndo, isFalse);

      expect(controller.canRedo, isFalse);
    });

    test('undo back to saved state clears dirty flag', () {
      final controller = EditorController();

      controller.setSourceImage('photo.jpg');

      controller.updateAdjustment(AdjustmentType.exposure, 1);

      controller.markSaved();

      controller.updateAdjustment(AdjustmentType.contrast, 20);

      expect(controller.session.isDirty, isTrue);

      controller.undo();

      expect(controller.session.adjustments.exposure, 1);

      expect(controller.session.adjustments.contrast, 0);

      expect(controller.session.isDirty, isFalse);
    });

    test('reset adjustments creates one undoable history entry', () {
      final controller = EditorController();

      controller.setSourceImage('photo.jpg');
      controller.updateAdjustment(AdjustmentType.exposure, 1.2);
      controller.updateAdjustment(AdjustmentType.contrast, 25);
      controller.updateAdjustment(AdjustmentType.saturation, -18);

      final historyLengthBeforeReset = controller.history.length;

      controller.resetAdjustments();

      expect(controller.session.adjustments.isDefault, isTrue);
      expect(controller.history, hasLength(historyLengthBeforeReset + 1));
      expect(controller.history.last.label, 'Reset Adjustments');
      expect(controller.history.last.action, EditorHistoryAction.reset);

      controller.undo();

      expect(controller.session.adjustments.exposure, 1.2);
      expect(controller.session.adjustments.contrast, 25);
      expect(controller.session.adjustments.saturation, -18);

      controller.redo();

      expect(controller.session.adjustments.isDefault, isTrue);
    });

    test('reset at default state does not create history', () {
      final controller = EditorController();

      controller.setSourceImage('photo.jpg');

      final historyLength = controller.history.length;

      controller.resetAdjustments();

      expect(controller.history, hasLength(historyLength));
      expect(controller.historyIndex, 0);
    });

    test('ninety degree rotation gets descriptive history label', () {
      final controller = EditorController();

      controller.setSourceImage('photo.jpg');

      controller.updateTransform(
        controller.session.transform.rotateClockwise(),
      );

      expect(controller.history.last.label, 'Rotate Right 90°');

      controller.updateTransform(
        controller.session.transform.rotateCounterClockwise(),
      );

      expect(controller.history.last.label, 'Rotate Left 90°');
    });
  });
}
