import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/curve_point.dart';
import 'package:presetstudio/features/editor/domain/tone_curves.dart';
import 'package:presetstudio/features/editor/presentation/widgets/desktop_editor_shell.dart';
import 'package:presetstudio/features/editor/presentation/widgets/tone_curve_editor.dart';

void main() {
  group('Desktop tone curves integration', () {
    testWidgets('desktop mounts curves only when an image is loaded', (
      tester,
    ) async {
      final controller = EditorController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: DesktopEditorShell(
            controller: controller,
            onImportImage: () async {},
            isImporting: false,
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('desktop-tone-curve-editor')),
        findsNothing,
      );

      controller.setSourceImage('missing-test-image.jpg');
      await tester.pump();

      expect(
        find.byKey(const ValueKey('desktop-tone-curve-editor')),
        findsOneWidget,
      );
    });

    testWidgets('desktop curve interaction updates state as one history edit', (
      tester,
    ) async {
      final controller = EditorController();
      addTearDown(controller.dispose);
      controller.setSourceImage('missing-test-image.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: DesktopEditorShell(
            controller: controller,
            onImportImage: () async {},
            isImporting: false,
          ),
        ),
      );

      final curveEditor = tester.widget<ToneCurveEditor>(
        find.byKey(const ValueKey('desktop-tone-curve-editor')),
      );
      final editedCurves = ToneCurves.initial.copyWith(
        master: ToneCurve(
          points: [
            CurvePoint(input: 0, output: 0),
            CurvePoint(input: 0.5, output: 0.7),
            CurvePoint(input: 1, output: 1),
          ],
        ),
      );

      curveEditor.onInteractionStart?.call();
      curveEditor.onChanged(editedCurves);
      curveEditor.onInteractionEnd?.call();
      await tester.pump();

      expect(controller.session.effectiveToneCurves, editedCurves);
      expect(controller.history, hasLength(2));
      expect(controller.history.last.label, 'Tone Curves');
      expect(controller.canUndo, isTrue);

      controller.undo();
      await tester.pump();

      expect(controller.session.effectiveToneCurves.isDefault, isTrue);
    });
  });
}
