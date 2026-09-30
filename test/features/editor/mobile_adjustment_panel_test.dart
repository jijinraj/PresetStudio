import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/adjustment_type.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_ruler_control.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_adjustment_panel.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_tone_curve_workspace.dart';
import 'package:presetstudio/theme/preset_studio_theme.dart';

void main() {
  testWidgets('adjustment selector exposes scalar adjustments and curves', (
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
    expect(
      find.byKey(const ValueKey('mobile-adjustment-curves')),
      findsOneWidget,
    );
    expect(find.byType(EditorRulerControl), findsOneWidget);
  });

  testWidgets('curves selector opens dedicated mobile workspace', (
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

    final curves = find.byKey(const ValueKey('mobile-adjustment-curves'));
    await tester.ensureVisible(curves);
    await tester.tap(curves);
    await tester.pumpAndSettle();

    expect(find.byType(MobileToneCurveWorkspace), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tone-curve-gesture-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tone-curve-channel-master')),
      findsOneWidget,
    );
  });
}
