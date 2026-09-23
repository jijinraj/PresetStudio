import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/desktop_editor_shell.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_shell.dart';

void main() {
  group('Exposure editor integration', () {
    testWidgets('desktop hides exposure control without an image', (
      tester,
    ) async {
      final controller = EditorController();

      await tester.pumpWidget(
        MaterialApp(
          home: DesktopEditorShell(
            controller: controller,
            onImportImage: () async {},
            isImporting: false,
          ),
        ),
      );

      expect(find.text('Select an image to start editing.'), findsOneWidget);

      expect(find.text('Exposure'), findsNothing);

      expect(
        find.byKey(const ValueKey('adjustment-exposure-slider')),
        findsNothing,
      );
    });

    testWidgets('desktop exposure control updates editor state', (
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

      expect(find.text('Exposure'), findsOneWidget);

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('adjustment-exposure-slider')),
      );

      expect(slider.onChanged, isNotNull);

      slider.onChanged?.call(1.24);

      await tester.pump();

      expect(controller.session.adjustments.exposure, 1.2);

      expect(find.text('+1.2'), findsOneWidget);
    });

    testWidgets('mobile does not expose adjustment controls without an image', (
      tester,
    ) async {
      final controller = EditorController();

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

      expect(find.text('Exposure'), findsNothing);
    });

    testWidgets('mobile Edit tool opens exposure controls', (tester) async {
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

      await tester.tap(find.text('Edit'));

      await tester.pumpAndSettle();

      expect(find.text('Exposure'), findsOneWidget);

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('adjustment-exposure-slider')),
      );

      expect(slider.onChanged, isNotNull);

      slider.onChanged?.call(-1.26);

      await tester.pump();

      expect(controller.session.adjustments.exposure, -1.3);

      expect(find.text('-1.3'), findsOneWidget);
    });
  });
}
