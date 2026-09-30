import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/desktop_editor_shell.dart';

void main() {
  testWidgets('desktop exposes the reusable HSL color mixer', (tester) async {
    tester.view.physicalSize = const Size(1100, 720);
    tester.view.devicePixelRatio = 1.0;

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

    final panelScroll = find.descendant(
      of: find.byKey(const ValueKey('desktop-adjustments-scroll')),
      matching: find.byType(Scrollable),
    );
    final mixer = find.byKey(const ValueKey('desktop-hsl-color-mixer'));

    await tester.scrollUntilVisible(mixer, 300, scrollable: panelScroll);

    expect(mixer, findsOneWidget);
    expect(
      find.byKey(const ValueKey('hsl-color-mixer-range-red')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hsl-color-mixer-component-saturation')),
      findsOneWidget,
    );
  });

  testWidgets('desktop HSL drag creates one History operation', (tester) async {
    tester.view.physicalSize = const Size(1100, 720);
    tester.view.devicePixelRatio = 1.0;

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

    final panelScroll = find.descendant(
      of: find.byKey(const ValueKey('desktop-adjustments-scroll')),
      matching: find.byType(Scrollable),
    );
    final mixer = find.byKey(const ValueKey('desktop-hsl-color-mixer'));

    await tester.scrollUntilVisible(mixer, 300, scrollable: panelScroll);
    await tester.pumpAndSettle();

    final initialHistoryLength = controller.history.length;
    final rulerSurface = find.byKey(
      const ValueKey('editor-ruler-gesture-surface'),
    );

    expect(rulerSurface, findsOneWidget);

    await tester.drag(rulerSurface, const Offset(-48, 0));
    await tester.pumpAndSettle();

    expect(controller.session.hslColorMixer.red.saturation, isNot(0));
    expect(controller.history.length, initialHistoryLength + 1);
    expect(controller.history.last.label, 'HSL Color Mixer');

    controller.undo();
    expect(controller.session.hslColorMixer.red.saturation, 0);

    controller.redo();
    expect(controller.session.hslColorMixer.red.saturation, isNot(0));
  });
}
