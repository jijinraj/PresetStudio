import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/desktop_editor_shell.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_shell.dart';

void main() {
  group('Contrast and saturation editor integration', () {
    testWidgets('desktop exposes contrast and saturation controls', (
      tester,
    ) async {
      final controller = EditorController();

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

      expect(
        find.byKey(const ValueKey('adjustment-contrast-slider')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey('adjustment-saturation-slider')),
        findsOneWidget,
      );

      final contrastSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('adjustment-contrast-slider')),
      );

      contrastSlider.onChanged?.call(35.0);

      await tester.pump();

      expect(controller.session.adjustments.contrast, 35.0);

      final saturationSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('adjustment-saturation-slider')),
      );

      saturationSlider.onChanged?.call(-40.0);

      await tester.pump();

      expect(controller.session.adjustments.saturation, -40.0);
    });

    testWidgets('mobile edit sheet exposes contrast and saturation controls', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = EditorController();

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

      await tester.tap(find.byKey(const ValueKey('mobile-tool-adjust')));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('adjustment-contrast-slider')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey('adjustment-saturation-slider')),
        findsOneWidget,
      );

      final contrastSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('adjustment-contrast-slider')),
      );

      contrastSlider.onChanged?.call(-25.0);

      await tester.pump();

      expect(controller.session.adjustments.contrast, -25.0);

      final saturationSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('adjustment-saturation-slider')),
      );

      saturationSlider.onChanged?.call(60.0);

      await tester.pump();

      expect(controller.session.adjustments.saturation, 60.0);
    });
  });
}
