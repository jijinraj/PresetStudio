import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/adjustment_type.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_ruler_control.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_adjustment_panel.dart';
import 'package:presetstudio/theme/preset_studio_theme.dart';

void main() {
  testWidgets('adjustment selector exposes every supported adjustment', (
    tester,
  ) async {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.setSourceImage('missing-test-image.jpg');

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: Scaffold(body: MobileAdjustmentPanel(controller: controller)),
      ),
    );

    for (final type in AdjustmentType.values) {
      expect(
        find.byKey(ValueKey('mobile-adjustment-${type.name}')),
        findsOneWidget,
      );
    }

    expect(find.byType(EditorRulerControl), findsOneWidget);
  });

  testWidgets('reset all keeps adjustment reset in existing controller path', (
    tester,
  ) async {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.setSourceImage('missing-test-image.jpg');
    controller.updateAdjustment(AdjustmentType.exposure, 1.5);
    controller.updateAdjustment(AdjustmentType.temperature, 25);

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: Scaffold(body: MobileAdjustmentPanel(controller: controller)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('mobile-adjustment-reset-all')));
    await tester.pump();

    expect(controller.session.adjustments.isDefault, isTrue);
    expect(controller.history.last.label, 'Reset Adjustments');
  });
}
