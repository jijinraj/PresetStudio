import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/curve_point.dart';
import 'package:presetstudio/features/editor/domain/editor_session.dart';
import 'package:presetstudio/features/editor/domain/tone_curves.dart';

void main() {
  ToneCurves modifiedCurves(double output) {
    return ToneCurves.initial.copyWith(
      master: ToneCurve(points: [CurvePoint(input: 0.5, output: output)]),
    );
  }

  group('Tone Curves editor state', () {
    test('editor session defaults to neutral tone curves', () {
      const session = EditorSession.initial;

      expect(session.effectiveToneCurves, ToneCurves.initial);
      expect(session.effectiveToneCurves.isDefault, isTrue);
    });

    test(
      'updating tone curves marks the session dirty and records history',
      () {
        final controller = EditorController();
        addTearDown(controller.dispose);

        controller.setSourceImage('photo.jpg');
        controller.updateToneCurves(modifiedCurves(0.65));

        expect(controller.session.effectiveToneCurves.isDefault, isFalse);
        expect(controller.session.isDirty, isTrue);
        expect(controller.history, hasLength(2));
        expect(controller.history.last.label, 'Tone Curves');
      },
    );

    test('tone curve updates clear the active preset', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      controller.applyPreset(
        presetId: 'preset-001',
        adjustments: controller.session.adjustments,
      );

      controller.updateToneCurves(modifiedCurves(0.65));

      expect(controller.session.activePresetId, isNull);
    });

    test('undo and redo restore tone curve state', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      final curves = modifiedCurves(0.65);
      controller.updateToneCurves(curves);

      controller.undo();
      expect(controller.session.effectiveToneCurves, ToneCurves.initial);
      expect(controller.session.isDirty, isFalse);

      controller.redo();
      expect(controller.session.effectiveToneCurves, curves);
      expect(controller.session.isDirty, isTrue);
    });

    test(
      'semantic transaction groups curve updates into one history entry',
      () {
        final controller = EditorController();
        addTearDown(controller.dispose);

        controller.setSourceImage('photo.jpg');
        controller.beginEditTransaction();

        controller.updateToneCurves(modifiedCurves(0.55));
        controller.updateToneCurves(modifiedCurves(0.7));

        expect(controller.history, hasLength(1));

        controller.endEditTransaction();

        expect(controller.history, hasLength(2));
        expect(controller.history.last.label, 'Tone Curves');
        expect(controller.session.effectiveToneCurves, modifiedCurves(0.7));
      },
    );

    test('cancel transaction restores exact tone curve state', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      final before = modifiedCurves(0.6);
      controller.updateToneCurves(before);

      controller.beginEditTransaction();
      controller.updateToneCurves(modifiedCurves(0.8));
      controller.cancelEditTransaction();

      expect(controller.session.effectiveToneCurves, before);
      expect(controller.history, hasLength(2));
    });

    test('disabling a curve history entry removes only that operation', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      controller.updateToneCurves(modifiedCurves(0.65));
      controller.updateToneCurves(modifiedCurves(0.8));

      controller.setHistoryEntryEnabled(1, false);

      expect(controller.session.effectiveToneCurves, modifiedCurves(0.8));

      controller.setHistoryEntryEnabled(2, false);

      expect(controller.session.effectiveToneCurves, ToneCurves.initial);
    });

    test('setting a new source image resets tone curves', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('first.jpg');
      controller.updateToneCurves(modifiedCurves(0.65));

      controller.setSourceImage('second.jpg');

      expect(controller.session.effectiveToneCurves, ToneCurves.initial);
      expect(controller.session.isDirty, isFalse);
    });

    test('mark saved includes tone curves in dirty-state comparison', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      final saved = modifiedCurves(0.65);
      controller.updateToneCurves(saved);
      controller.markSaved();

      expect(controller.session.isDirty, isFalse);

      controller.updateToneCurves(modifiedCurves(0.8));
      expect(controller.session.isDirty, isTrue);

      controller.updateToneCurves(saved);
      expect(controller.session.isDirty, isFalse);
    });
  });
}
