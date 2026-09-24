import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/adjustment_type.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_shell.dart';

void main() {
  testWidgets('mobile exposes one global before-after control in viewport', (
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
    controller.updateAdjustment(AdjustmentType.exposure, 1.0);

    await tester.pumpWidget(
      MaterialApp(
        home: MobileEditorShell(
          controller: controller,
          onImportImage: () async {},
          isImporting: false,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('mobile-before-after')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-focused-before-after')),
      findsNothing,
    );

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mobile-before-after')), findsOneWidget);

    final exposureFinder = find.byKey(
      const ValueKey('adjustment-exposure-slider'),
    );

    final exposureSlider = tester.widget<Slider>(exposureFinder);
    exposureSlider.onChangeStart?.call(1.0);

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-focused-adjustment-bar')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('mobile-before-after')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-focused-before-after')),
      findsNothing,
    );
  });
}
