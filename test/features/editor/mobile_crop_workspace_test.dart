import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_shell.dart';

void main() {
  testWidgets('mobile Crop tool opens full-screen crop workspace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = EditorController();
    addTearDown(controller.dispose);

    controller.setSourceImage('missing-test-image.jpg');

    await tester.pumpWidget(
      MaterialApp(
        home: MobileEditorShell(
          controller: controller,
          onImportImage: () async {},
          isImporting: false,
        ),
      ),
    );

    await tester.tap(find.text('Crop'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('crop-frame')), findsOneWidget);
    expect(find.text('Crop & Straighten'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('crop-cancel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('crop-frame')), findsNothing);
    expect(controller.isEditTransactionActive, isFalse);
  });

  testWidgets('mobile Done keeps committed crop visible in normal editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = EditorController();
    addTearDown(controller.dispose);

    controller.setSourceImage('missing-test-image.jpg');

    await tester.pumpWidget(
      MaterialApp(
        home: MobileEditorShell(
          controller: controller,
          onImportImage: () async {},
          isImporting: false,
        ),
      ),
    );

    await tester.tap(find.text('Crop'));
    await tester.pumpAndSettle();

    // This regression is about committed-crop rendering after Done, not the
    // scroll position of the compact horizontal ratio strip. Invoke the chip
    // callback directly so the test remains stable as controls are added beside
    // that strip.
    final ratioChip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('crop-ratio-1x1')),
    );
    ratioChip.onSelected?.call(true);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('crop-done')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('crop-frame')), findsNothing);

    final committedFrame = tester.widget<AspectRatio>(
      find.byKey(const ValueKey('editor-crop-output-frame')),
    );

    expect(committedFrame.aspectRatio, closeTo(1.0, 0.000001));
    expect(controller.session.crop.aspectRatio, closeTo(1.0, 0.000001));
  });
}
