import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/desktop_editor_shell.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_ruler_control.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_shell.dart';

void main() {
  group('Color controls editor integration', () {
    testWidgets('desktop exposes temperature tint vibrance and saturation', (
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

      expect(
        find.byKey(const ValueKey('adjustment-temperature-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('adjustment-tint-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('adjustment-vibrance-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('adjustment-saturation-slider')),
        findsOneWidget,
      );

      tester
          .widget<Slider>(
            find.byKey(const ValueKey('adjustment-temperature-slider')),
          )
          .onChanged
          ?.call(35);
      tester
          .widget<Slider>(find.byKey(const ValueKey('adjustment-tint-slider')))
          .onChanged
          ?.call(-25);
      tester
          .widget<Slider>(
            find.byKey(const ValueKey('adjustment-vibrance-slider')),
          )
          .onChanged
          ?.call(50);

      await tester.pump();

      expect(controller.session.adjustments.temperature, 35);
      expect(controller.session.adjustments.tint, -25);
      expect(controller.session.adjustments.vibrance, 50);
    });

    testWidgets('mobile adjustment selector exposes the complete Color group', (
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

      for (final id in <String>[
        'mobile-adjustment-temperature',
        'mobile-adjustment-tint',
        'mobile-adjustment-vibrance',
        'mobile-adjustment-saturation',
      ]) {
        expect(find.byKey(ValueKey(id)), findsOneWidget);
      }

      final vibrance = find.byKey(const ValueKey('mobile-adjustment-vibrance'));
      await tester.ensureVisible(vibrance);
      await tester.tap(vibrance);
      await tester.pumpAndSettle();

      final ruler = tester.widget<EditorRulerControl>(
        find.byType(EditorRulerControl),
      );
      ruler.onInteractionStart?.call();
      ruler.onChanged(60);
      ruler.onInteractionEnd?.call();
      await tester.pump();

      expect(controller.session.adjustments.vibrance, 60);
    });
  });
}
