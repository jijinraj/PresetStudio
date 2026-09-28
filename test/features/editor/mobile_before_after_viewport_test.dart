import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/adjustment_type.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_ruler_control.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_shell.dart';

void main() {
  testWidgets('mobile keeps one global before-after control while adjusting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = EditorController();
    addTearDown(controller.dispose);

    controller.setSourceImage('missing-test-image.jpg');
    controller.updateAdjustment(AdjustmentType.exposure, 1.0);

    await tester.pumpWidget(
      MaterialApp(
        home: MobileEditorShell(
          controller: controller,
          onImportImage: () async {},
          isImporting: false,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('mobile-before-after')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mobile-tool-adjust')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mobile-before-after')), findsOneWidget);
    expect(find.byType(EditorRulerControl), findsOneWidget);
    expect(find.byType(Slider), findsNothing);

    final ruler = tester.widget<EditorRulerControl>(
      find.byType(EditorRulerControl),
    );
    ruler.onInteractionStart?.call();
    ruler.onChanged(1.4);
    ruler.onInteractionEnd?.call();
    await tester.pump();

    expect(find.byKey(const ValueKey('mobile-before-after')), findsOneWidget);
    expect(controller.session.adjustments.exposure, 1.4);
  });
}
