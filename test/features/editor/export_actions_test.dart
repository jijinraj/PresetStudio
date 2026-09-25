import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/desktop_editor_shell.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_shell.dart';

void main() {
  testWidgets('desktop Export invokes callback when an image is loaded', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.setSourceImage('missing-test-image.jpg');

    var exportCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: DesktopEditorShell(
          controller: controller,
          onImportImage: () async {},
          isImporting: false,
          onExportImage: () async {
            exportCount += 1;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('desktop-export')));
    await tester.pump();

    expect(exportCount, 1);
  });

  testWidgets('mobile Export invokes callback when an image is loaded', (
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

    var exportCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MobileEditorShell(
          controller: controller,
          onImportImage: () async {},
          isImporting: false,
          onExportImage: () async {
            exportCount += 1;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('mobile-export')));
    await tester.pump();

    expect(exportCount, 1);
  });
}
