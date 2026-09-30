import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/curve_point.dart';
import 'package:presetstudio/features/editor/domain/tone_curves.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_tone_curve_workspace.dart';
import 'package:presetstudio/theme/preset_studio_theme.dart';

void main() {
  testWidgets('done commits one semantic tone curves history entry', (
    tester,
  ) async {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.setSourceImage('missing-test-image.jpg');

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: MobileToneCurveWorkspace(controller: controller, onClose: () {}),
      ),
    );
    await tester.pump();

    controller.updateToneCurves(
      ToneCurves.initial.copyWith(
        master: ToneCurve(
          points: [
            CurvePoint(input: 0, output: 0),
            CurvePoint(input: 0.5, output: 0.7),
            CurvePoint(input: 1, output: 1),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('mobile-curves-done')));
    await tester.pump();

    expect(controller.history.last.label, 'Tone Curves');
    expect(controller.isEditTransactionActive, isFalse);
  });

  testWidgets('cancel restores curves from workspace entry', (tester) async {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.setSourceImage('missing-test-image.jpg');
    final before = controller.session.effectiveToneCurves;

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: MobileToneCurveWorkspace(controller: controller, onClose: () {}),
      ),
    );
    await tester.pump();

    controller.updateToneCurves(
      before.copyWith(
        red: ToneCurve(
          points: [
            CurvePoint(input: 0, output: 0),
            CurvePoint(input: 0.5, output: 0.8),
            CurvePoint(input: 1, output: 1),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('mobile-curves-cancel')));
    await tester.pump();

    expect(controller.session.effectiveToneCurves, before);
    expect(controller.isEditTransactionActive, isFalse);
  });
}
