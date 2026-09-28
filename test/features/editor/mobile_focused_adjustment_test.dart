import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_ruler_control.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_adjustment_panel.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_shell.dart';

void main() {
  testWidgets('mobile adjust panel uses one precision ruler at a time', (
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

    expect(find.byType(MobileAdjustmentPanel), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-adjustment-selector')),
      findsOneWidget,
    );
    expect(find.byType(EditorRulerControl), findsOneWidget);
    expect(find.byType(Slider), findsNothing);

    final historyCount = controller.history.length;
    var ruler = tester.widget<EditorRulerControl>(
      find.byType(EditorRulerControl),
    );

    expect(ruler.minValue, -5);
    expect(ruler.maxValue, 5);
    expect(ruler.precisionStep, 0.01);

    ruler.onInteractionStart?.call();
    await tester.pump();

    final topBarVisibility = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('mobile-top-bar-visibility')),
    );
    final bottomDockVisibility = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('mobile-bottom-dock-visibility')),
    );
    final panelHeaderVisibility = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('mobile-context-panel-header')),
    );

    expect(topBarVisibility.opacity, 0);
    expect(bottomDockVisibility.opacity, 0);
    expect(panelHeaderVisibility.opacity, 0);
    expect(find.byKey(const ValueKey('mobile-before-after')), findsNothing);
    expect(find.byType(EditorRulerControl), findsOneWidget);

    ruler.onChanged(0.8);
    ruler.onChanged(1.2);
    ruler.onInteractionEnd?.call();
    await tester.pump();

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('mobile-top-bar-visibility')),
          )
          .opacity,
      1,
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('mobile-bottom-dock-visibility')),
          )
          .opacity,
      1,
    );

    expect(controller.session.adjustments.exposure, 1.2);
    expect(controller.history.length, historyCount + 1);
    expect(controller.history.last.label, contains('Exposure'));

    final contrast = find.byKey(const ValueKey('mobile-adjustment-contrast'));
    await tester.ensureVisible(contrast);
    await tester.tap(contrast);
    await tester.pumpAndSettle();

    ruler = tester.widget<EditorRulerControl>(find.byType(EditorRulerControl));
    expect(ruler.minValue, -100);
    expect(ruler.maxValue, 100);
    expect(ruler.precisionStep, 1);
    expect(find.byType(EditorRulerControl), findsOneWidget);
  });
}
