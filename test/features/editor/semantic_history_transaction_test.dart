import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/application/editor_history_entry.dart';
import 'package:presetstudio/features/editor/domain/adjustment_type.dart';

void main() {
  group('Semantic History transactions', () {
    test('compound edits create one explicitly labelled History operation', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');

      controller.beginSemanticEditTransaction(
        label: 'Crop · 4:5',
        action: EditorHistoryAction.crop,
      );

      controller.updateAdjustment(AdjustmentType.exposure, 1.0);
      controller.updateAdjustment(AdjustmentType.contrast, 20);

      expect(controller.isEditTransactionActive, isTrue);
      expect(controller.history, hasLength(1));

      controller.endEditTransaction();

      expect(controller.isEditTransactionActive, isFalse);
      expect(controller.history, hasLength(2));

      final entry = controller.history.last;

      expect(entry.label, 'Crop · 4:5');
      expect(entry.action, EditorHistoryAction.crop);
      expect(entry.beforeSession.adjustments.exposure, 0);
      expect(entry.beforeSession.adjustments.contrast, 0);
      expect(entry.session.adjustments.exposure, 1.0);
      expect(entry.session.adjustments.contrast, 20);
    });

    test('semantic label can be finalized at the end of an interaction', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');

      controller.beginSemanticEditTransaction(
        label: 'Straighten',
        action: EditorHistoryAction.transform,
      );

      controller.updateAdjustment(AdjustmentType.exposure, 0.4);
      controller.updateSemanticEditTransactionLabel('Straighten +1.4°');
      controller.endEditTransaction();

      expect(controller.history, hasLength(2));
      expect(controller.history.last.label, 'Straighten +1.4°');
      expect(controller.history.last.action, EditorHistoryAction.transform);
    });

    test('cancel restores the interaction start and adds no History entry', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      controller.updateAdjustment(AdjustmentType.saturation, 10);

      final historyLengthBefore = controller.history.length;

      controller.beginSemanticEditTransaction(
        label: 'Crop · Free',
        action: EditorHistoryAction.crop,
      );

      controller.updateAdjustment(AdjustmentType.exposure, 1.2);
      controller.updateAdjustment(AdjustmentType.contrast, 25);

      expect(controller.session.adjustments.exposure, 1.2);
      expect(controller.session.adjustments.contrast, 25);

      controller.cancelEditTransaction();

      expect(controller.isEditTransactionActive, isFalse);
      expect(controller.history, hasLength(historyLengthBefore));
      expect(controller.session.adjustments.exposure, 0);
      expect(controller.session.adjustments.contrast, 0);
      expect(controller.session.adjustments.saturation, 10);
    });

    test('semantic transaction still suppresses a final no-op', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');

      controller.beginSemanticEditTransaction(
        label: 'Straighten 0°',
        action: EditorHistoryAction.transform,
      );

      controller.updateAdjustment(AdjustmentType.exposure, 1.0);
      controller.updateAdjustment(AdjustmentType.exposure, 0);

      controller.endEditTransaction();

      expect(controller.history, hasLength(1));
      expect(controller.history.single.label, 'Original');
    });
  });
}
