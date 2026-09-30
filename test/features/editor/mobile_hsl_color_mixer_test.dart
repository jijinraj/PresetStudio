import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/hsl_color_mixer.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_adjustment_panel.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_hsl_color_mixer_workspace.dart';
import 'package:presetstudio/theme/preset_studio_theme.dart';

void main() {
  testWidgets('mobile adjustment panel exposes Color Mixer', (tester) async {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.setSourceImage('missing-test-image.jpg');

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: Scaffold(body: MobileAdjustmentPanel(controller: controller)),
      ),
    );

    final mixer = find.byKey(const ValueKey('mobile-adjustment-color-mixer'));
    await tester.ensureVisible(mixer);

    expect(mixer, findsOneWidget);
  });

  testWidgets('Color Mixer selector opens dedicated mobile workspace', (
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

    final mixer = find.byKey(const ValueKey('mobile-adjustment-color-mixer'));
    await tester.ensureVisible(mixer);
    await tester.tap(mixer);
    await tester.pumpAndSettle();

    expect(find.byType(MobileHslColorMixerWorkspace), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-hsl-color-mixer-editor')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hsl-color-mixer-range-red')),
      findsOneWidget,
    );
  });

  testWidgets('Done commits the mobile Color Mixer as one History operation', (
    tester,
  ) async {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.setSourceImage('missing-test-image.jpg');

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: MobileHslColorMixerWorkspace(
          controller: controller,
          onClose: () {},
        ),
      ),
    );
    await tester.pump();

    controller.updateHslColorMixer(
      HslColorMixer.initial.copyWith(red: HslColorAdjustment(saturation: 35)),
    );
    await tester.pump();

    expect(controller.history.length, 1);

    await tester.tap(find.byKey(const ValueKey('mobile-color-mixer-done')));
    await tester.pump();

    expect(controller.history.length, 2);
    expect(controller.history.last.label, 'HSL Color Mixer');
    expect(controller.session.hslColorMixer.red.saturation, 35);

    controller.undo();
    expect(controller.session.hslColorMixer, HslColorMixer.initial);
  });

  testWidgets('Cancel restores exact HSL state without adding History', (
    tester,
  ) async {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.setSourceImage('missing-test-image.jpg');
    controller.updateHslColorMixer(
      HslColorMixer.initial.copyWith(
        blue: HslColorAdjustment(hue: 12, luminance: -8),
      ),
    );
    final startingMixer = controller.session.hslColorMixer;
    final startingHistoryLength = controller.history.length;

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: MobileHslColorMixerWorkspace(
          controller: controller,
          onClose: () {},
        ),
      ),
    );
    await tester.pump();

    controller.updateHslColorMixer(
      startingMixer.copyWith(blue: startingMixer.blue.copyWith(saturation: 44)),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('mobile-color-mixer-cancel')));
    await tester.pump();

    expect(controller.session.hslColorMixer, startingMixer);
    expect(controller.history.length, startingHistoryLength);
  });

  testWidgets('Reset all participates in the workspace transaction', (
    tester,
  ) async {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.setSourceImage('missing-test-image.jpg');
    controller.updateHslColorMixer(
      HslColorMixer.initial.copyWith(
        green: HslColorAdjustment(saturation: 28),
        magenta: HslColorAdjustment(luminance: -17),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: MobileHslColorMixerWorkspace(
          controller: controller,
          onClose: () {},
        ),
      ),
    );
    await tester.pump();

    final before = controller.history.length;

    await tester.tap(
      find.byKey(const ValueKey('mobile-color-mixer-reset-all')),
    );
    await tester.pump();

    expect(controller.session.hslColorMixer, HslColorMixer.initial);
    expect(controller.history.length, before);

    await tester.tap(find.byKey(const ValueKey('mobile-color-mixer-done')));
    await tester.pump();

    expect(controller.history.length, before + 1);
    expect(controller.history.last.label, 'HSL Color Mixer');
  });
}
