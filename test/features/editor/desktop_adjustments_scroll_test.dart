import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/desktop_editor_shell.dart';

void main() {
  testWidgets(
    'desktop adjustment panel keeps an active scroll burst from changing sliders',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 620);
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
          home: DesktopEditorShell(
            controller: controller,
            onImportImage: () async {},
            isImporting: false,
          ),
        ),
      );

      final panelScrollable = find.descendant(
        of: find.byKey(const ValueKey('desktop-adjustments-scroll')),
        matching: find.byType(Scrollable),
      );

      expect(panelScrollable, findsOneWidget);

      final scrollableState = tester.state<ScrollableState>(panelScrollable);
      expect(scrollableState.position.maxScrollExtent, greaterThan(0));

      // Start a real panel-owned wheel burst over non-slider content.
      // The panel's ScrollNotification marks the burst as panel-owned.
      final panelHeading = find.text('Adjustments');
      final initialPanelScroll = scrollableState.position.pixels;

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(panelHeading),
          scrollDelta: const Offset(0, 40),
        ),
      );
      await tester.pump();

      expect(scrollableState.position.pixels, greaterThan(initialPanelScroll));

      final exposureInteraction = find.byKey(
        const ValueKey('adjustment-exposure-slider-interaction'),
      );

      final beforePanelScroll = scrollableState.position.pixels;

      // Even though this event is now over a slider, the active panel burst
      // must keep ownership and continue scrolling instead of editing value.
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(exposureInteraction),
          scrollDelta: const Offset(0, 40),
        ),
      );
      await tester.pump();

      expect(controller.session.adjustments.exposure, 0.0);
      expect(scrollableState.position.pixels, greaterThan(beforePanelScroll));

      // Once the panel burst has settled, direct wheel input over the slider
      // returns to the normal PresetStudio adjustment behavior.
      await tester.pump(const Duration(milliseconds: 350));

      final panelOffsetAfterBurst = scrollableState.position.pixels;

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(exposureInteraction),
          scrollDelta: const Offset(0, -20),
        ),
      );
      await tester.pump();

      expect(controller.session.adjustments.exposure, 0.1);
      expect(scrollableState.position.pixels, panelOffsetAfterBurst);
    },
  );
}
