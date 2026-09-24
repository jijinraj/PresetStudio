import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/desktop_editor_shell.dart';

void main() {
  testWidgets('desktop opens and cancels the crop workspace', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
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
        home: DesktopEditorShell(
          controller: controller,
          onImportImage: () async {},
          isImporting: false,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('desktop-open-crop')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('desktop-open-crop')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('crop-frame')), findsOneWidget);
    expect(controller.isEditTransactionActive, isTrue);

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Adjustments'), findsNothing);
    expect(find.byKey(const ValueKey('desktop-open-crop')), findsNothing);

    final beforeAfterButton = tester.widget<Widget>(
      find.byKey(const ValueKey('desktop-before-after')),
    );
    expect(beforeAfterButton, isNotNull);

    await tester.tap(find.byKey(const ValueKey('crop-cancel')));
    await tester.pump();

    expect(find.byKey(const ValueKey('crop-frame')), findsNothing);
    expect(controller.isEditTransactionActive, isFalse);
    expect(find.text('Adjustments'), findsOneWidget);
    expect(find.byKey(const ValueKey('desktop-open-crop')), findsOneWidget);
  });

  testWidgets('desktop Done keeps committed crop visible in normal editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
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
        home: DesktopEditorShell(
          controller: controller,
          onImportImage: () async {},
          isImporting: false,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('desktop-open-crop')));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('crop-ratio-3x2')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('crop-done')));
    await tester.pump();

    expect(find.byKey(const ValueKey('crop-frame')), findsNothing);

    final committedFrame = tester.widget<AspectRatio>(
      find.byKey(const ValueKey('editor-crop-output-frame')),
    );

    expect(committedFrame.aspectRatio, closeTo(1.5, 0.000001));
    expect(controller.session.crop.aspectRatio, closeTo(1.5, 0.000001));
    expect(controller.history.last.label, 'Crop · 3:2');
  });
}
