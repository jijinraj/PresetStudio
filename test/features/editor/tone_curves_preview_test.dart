import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/curve_point.dart';
import 'package:presetstudio/features/editor/domain/tone_curves.dart';

void main() {
  ToneCurves liftedMasterCurve() {
    return ToneCurves.initial.copyWith(
      master: ToneCurve(points: [CurvePoint(input: 0.5, output: 0.7)]),
    );
  }

  test('curve-only edits enable before comparison and reset', () {
    final controller = EditorController();
    addTearDown(controller.dispose);

    controller.setSourceImage('photo.jpg');
    controller.updateToneCurves(liftedMasterCurve());

    expect(controller.canCompareBefore, isTrue);
    expect(controller.canResetAdjustments, isTrue);

    controller.resetAdjustments();

    expect(controller.session.effectiveToneCurves, ToneCurves.initial);
    expect(controller.canCompareBefore, isFalse);
  });

  test('before preview uses identity curves and restores edited curves', () {
    final controller = EditorController();
    addTearDown(controller.dispose);

    controller.setSourceImage('photo.jpg');
    final curves = liftedMasterCurve();
    controller.updateToneCurves(curves);

    expect(controller.previewToneCurves, curves);

    controller.beginBeforePreview();
    expect(controller.previewToneCurves, ToneCurves.initial);

    controller.endBeforePreview();
    expect(controller.previewToneCurves, curves);
  });
}
