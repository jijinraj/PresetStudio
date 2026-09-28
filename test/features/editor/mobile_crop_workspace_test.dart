import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_ruler_control.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_shell.dart';

void main() {
  testWidgets('mobile Crop tool opens full-screen crop workspace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

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

    await tester.tap(find.text('Crop'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('crop-frame')), findsOneWidget);
    expect(find.text('Crop'), findsOneWidget);
    expect(find.byType(EditorRulerControl), findsOneWidget);
    expect(find.byKey(const ValueKey('crop-reset')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('crop-cancel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('crop-frame')), findsNothing);
    expect(controller.isEditTransactionActive, isFalse);
  });

  testWidgets('mobile Done keeps committed crop visible in normal editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

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

    await tester.tap(find.text('Crop'));
    await tester.pumpAndSettle();

    // This regression is about committed-crop rendering after Done, not the
    // current viewport of the lazily built horizontal ratio strip. Scroll the
    // target ratio into view before selecting it.
    final ratioFinder = find.byKey(const ValueKey('crop-ratio-1x1'));
    await tester.scrollUntilVisible(
      ratioFinder,
      120,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('crop-ratio-list')),
        matching: find.byType(Scrollable),
      ),
    );
    final ratioChip = tester.widget<ChoiceChip>(ratioFinder);
    ratioChip.onSelected?.call(true);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('crop-done')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('crop-frame')), findsNothing);

    final committedFrame = tester.widget<AspectRatio>(
      find.byKey(const ValueKey('editor-crop-output-frame')),
    );

    expect(committedFrame.aspectRatio, closeTo(1.0, 0.000001));
    expect(controller.session.crop.aspectRatio, closeTo(1.0, 0.000001));
  });

  testWidgets('mobile directional guide controls fit without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

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

    await tester.tap(find.text('Crop'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('composition-guide-menu')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('composition-guide-golden-spiral')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('composition-guide-golden-spiral-overlay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('composition-guide-orientation-menu')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('composition-guide-style-menu')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('composition-guide-style-menu')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('composition-guide-color-yellow')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('composition-guide-style-menu')),
    );
    await tester.pumpAndSettle();

    final opacitySlider = tester.widget<Slider>(
      find.byKey(const ValueKey('composition-guide-opacity-slider')),
    );
    opacitySlider.onChanged?.call(0.55);
    await tester.pump();

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('composition-guide-orientation-menu')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('composition-guide-rotate')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('crop-cancel')));
    await tester.pumpAndSettle();

    expect(controller.isEditTransactionActive, isFalse);
  });
  testWidgets('mobile straighten ruler enters immersive crop interaction', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

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

    await tester.tap(find.text('Crop'));
    await tester.pumpAndSettle();

    var ruler = tester.widget<EditorRulerControl>(
      find.byType(EditorRulerControl),
    );
    ruler.onInteractionStart?.call();
    ruler.onChanged(2.4);
    await tester.pump(const Duration(milliseconds: 180));

    final hiddenTopBar = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('mobile-crop-top-bar-visibility')),
    );
    final hiddenSecondaryControls = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('mobile-crop-secondary-controls')),
    );

    expect(hiddenTopBar.opacity, 0);
    expect(hiddenSecondaryControls.opacity, 0);
    expect(controller.session.crop.straightenDegrees, closeTo(2.4, 0.000001));

    ruler = tester.widget<EditorRulerControl>(find.byType(EditorRulerControl));
    ruler.onInteractionEnd?.call();
    await tester.pump(const Duration(milliseconds: 180));

    final visibleTopBar = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('mobile-crop-top-bar-visibility')),
    );
    expect(visibleTopBar.opacity, 1);

    await tester.tap(find.byKey(const ValueKey('crop-reset')));
    await tester.pump();
    expect(controller.session.crop.straightenDegrees, 0);

    await tester.tap(find.byKey(const ValueKey('crop-cancel')));
    await tester.pumpAndSettle();
  });
}
