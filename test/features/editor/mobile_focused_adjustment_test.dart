import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_shell.dart';

void main() {
  testWidgets('mobile enters focused adjustment mode while editing', (
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

    await tester.tap(find.text('Edit'));

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-edit-sheet-surface')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey('mobile-focused-adjustment-bar')),
      findsNothing,
    );

    final exposureFinder = find.byKey(
      const ValueKey('adjustment-exposure-slider'),
    );

    expect(exposureFinder, findsOneWidget);

    var exposureSlider = tester.widget<Slider>(exposureFinder);

    expect(exposureSlider.onChangeStart, isNotNull);

    exposureSlider.onChangeStart?.call(0.0);

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-focused-adjustment-bar')),
      findsOneWidget,
    );

    expect(find.byKey(const ValueKey('mobile-focused-slider')), findsOneWidget);

    expect(
      find.byKey(const ValueKey('mobile-focused-decrement')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey('mobile-focused-increment')),
      findsOneWidget,
    );

    expect(find.byKey(const ValueKey('mobile-focused-close')), findsOneWidget);

    final focusedSlider = tester.widget<Slider>(
      find.byKey(const ValueKey('mobile-focused-slider')),
    );

    focusedSlider.onChanged?.call(1.2);

    await tester.pump();

    expect(controller.session.adjustments.exposure, 1.2);

    await tester.tap(find.byKey(const ValueKey('mobile-focused-increment')));

    await tester.pump();

    expect(controller.session.adjustments.exposure, closeTo(1.3, 0.0001));

    await tester.tap(find.byKey(const ValueKey('mobile-focused-decrement')));

    await tester.pump();

    expect(controller.session.adjustments.exposure, closeTo(1.2, 0.0001));

    await tester.tap(find.byKey(const ValueKey('mobile-focused-close')));

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-focused-adjustment-bar')),
      findsNothing,
    );

    expect(
      find.byKey(const ValueKey('adjustment-exposure-slider')),
      findsOneWidget,
    );
  });
}
