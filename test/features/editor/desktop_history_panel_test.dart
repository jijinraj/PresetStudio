import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/adjustment_type.dart';
import 'package:presetstudio/features/editor/presentation/widgets/desktop_editor_shell.dart';

void main() {
  Future<EditorController> pumpHistoryShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = EditorController();
    addTearDown(controller.dispose);

    controller.setSourceImage('missing-test-image.jpg');
    controller.updateAdjustment(AdjustmentType.exposure, 1.0);
    controller.updateAdjustment(AdjustmentType.contrast, 20);
    controller.updateAdjustment(AdjustmentType.saturation, 30);

    await tester.pumpWidget(
      MaterialApp(
        home: DesktopEditorShell(
          controller: controller,
          onImportImage: () async {},
          isImporting: false,
        ),
      ),
    );

    return controller;
  }

  testWidgets('desktop History panel can collapse and expand', (tester) async {
    await pumpHistoryShell(tester);

    expect(find.byKey(const ValueKey('editor-history-list')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('desktop-history-toggle')));
    await tester.pump();

    expect(find.byKey(const ValueKey('editor-history-list')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('desktop-history-toggle')));
    await tester.pump();

    expect(find.byKey(const ValueKey('editor-history-list')), findsOneWidget);
  });

  testWidgets('desktop Library no longer contains the Presets panel', (
    tester,
  ) async {
    await pumpHistoryShell(tester);

    expect(find.byKey(const ValueKey('desktop-presets-body')), findsNothing);
    expect(find.byKey(const ValueKey('desktop-presets-toggle')), findsNothing);
    expect(find.byKey(const ValueKey('editor-history-list')), findsOneWidget);
  });

  testWidgets('desktop eye toggle disables and re-enables an edit', (
    tester,
  ) async {
    final controller = await pumpHistoryShell(tester);

    final toggle = find.byKey(const ValueKey('history-entry-toggle-1'));

    expect(toggle, findsOneWidget);

    await tester.tap(toggle);
    await tester.pump();

    expect(controller.history[1].isEnabled, isFalse);
    expect(controller.session.adjustments.exposure, 0);
    expect(controller.session.adjustments.contrast, 20);
    expect(controller.session.adjustments.saturation, 30);

    await tester.tap(toggle);
    await tester.pump();

    expect(controller.history[1].isEnabled, isTrue);
    expect(controller.session.adjustments.exposure, 1.0);
  });

  testWidgets('desktop History menu can enable all disabled edits', (
    tester,
  ) async {
    final controller = await pumpHistoryShell(tester);

    controller.setHistoryEntryEnabled(1, false);
    await tester.pump();

    expect(controller.disabledHistoryCount, 1);

    await tester.tap(find.byKey(const ValueKey('desktop-history-menu')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('history-menu-enable-all')));
    await tester.pumpAndSettle();

    expect(controller.disabledHistoryCount, 0);
    expect(controller.session.adjustments.exposure, 1.0);
  });

  testWidgets('clear history keeps the effective current image state', (
    tester,
  ) async {
    final controller = await pumpHistoryShell(tester);

    controller.setHistoryEntryEnabled(1, false);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('desktop-history-menu')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('history-menu-clear')));
    await tester.pumpAndSettle();

    expect(find.text('Clear history?'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('desktop-history-clear-confirm')),
    );
    await tester.pumpAndSettle();

    expect(controller.history, hasLength(1));
    expect(controller.history.single.label, 'Current state');
    expect(controller.session.adjustments.exposure, 0);
    expect(controller.session.adjustments.contrast, 20);
    expect(controller.session.adjustments.saturation, 30);
  });
}
