import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/adjustment_type.dart';
import 'package:presetstudio/features/editor/presentation/widgets/desktop_editor_shell.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_image_viewport.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_rendered_image.dart';

void main() {
  testWidgets('desktop toggles persistent side-by-side comparison', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = EditorController();

    controller.setSourceImage('missing-test-image.jpg');
    controller.updateAdjustment(AdjustmentType.exposure, 1.0);

    await tester.pumpWidget(
      MaterialApp(
        home: DesktopEditorShell(
          controller: controller,
          onImportImage: () async {},
          isImporting: false,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('desktop-before-after')), findsOneWidget);
    expect(find.byKey(const ValueKey('desktop-side-by-side')), findsOneWidget);
    expect(find.text('BEFORE'), findsNothing);
    expect(find.text('AFTER'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('desktop-side-by-side')));
    await tester.pump();

    expect(find.text('BEFORE'), findsOneWidget);
    expect(find.text('AFTER'), findsOneWidget);
    expect(find.byType(EditorImageViewport), findsNWidgets(2));

    final renderedImages = tester
        .widgetList<EditorRenderedImage>(find.byType(EditorRenderedImage))
        .toList();

    expect(renderedImages, hasLength(2));
    expect(renderedImages.first.adjustments.isDefault, isTrue);
    expect(renderedImages.last.adjustments.exposure, 1.0);

    final viewers = tester
        .widgetList<InteractiveViewer>(
          find.byKey(const ValueKey('editor-viewport-interactive')),
        )
        .toList();

    expect(viewers, hasLength(2));
    expect(
      identical(
        viewers.first.transformationController,
        viewers.last.transformationController,
      ),
      isTrue,
    );

    controller.updateAdjustment(AdjustmentType.contrast, 20);
    await tester.pump();

    expect(find.text('BEFORE'), findsOneWidget);
    expect(find.text('AFTER'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('desktop-side-by-side')));
    await tester.pump();

    expect(find.text('BEFORE'), findsNothing);
    expect(find.text('AFTER'), findsNothing);
    expect(find.byType(EditorImageViewport), findsOneWidget);
  });
}
