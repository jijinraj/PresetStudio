import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/desktop_editor_shell.dart';
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

    testWidgets('mobile edit sheet exposes the complete Color group', (
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

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final sheetScrollable = find.descendant(
        of: find.byKey(const ValueKey('mobile-edit-scroll')),
        matching: find.byType(Scrollable),
      );

      for (final id in <String>[
        'adjustment-temperature-slider',
        'adjustment-tint-slider',
        'adjustment-vibrance-slider',
        'adjustment-saturation-slider',
      ]) {
        final finder = find.byKey(ValueKey(id));
        await tester.scrollUntilVisible(
          finder,
          250,
          scrollable: sheetScrollable.first,
        );
        expect(finder, findsOneWidget);
      }

      tester
          .widget<Slider>(
            find.byKey(const ValueKey('adjustment-vibrance-slider')),
          )
          .onChanged
          ?.call(60);

      await tester.pump();

      expect(controller.session.adjustments.vibrance, 60);
    });
  });
}
