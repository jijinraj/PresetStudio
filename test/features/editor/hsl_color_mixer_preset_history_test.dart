import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/application/editor_history_entry.dart';
import 'package:presetstudio/features/editor/domain/hsl_color_mixer.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';

void main() {
  test('applying a preset replaces HSL state in one preset history edit', () {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.setSourceImage('photo.jpg');
    controller.updateHslColorMixer(
      HslColorMixer.initial.withAdjustment(
        HslColorRange.green,
        HslColorAdjustment(saturation: 20),
      ),
    );
    final presetMixer = HslColorMixer.initial.withAdjustment(
      HslColorRange.blue,
      HslColorAdjustment(hue: -15, saturation: 40, luminance: -10),
    );
    controller.applyPreset(
      presetId: 'hsl-preset',
      presetName: 'HSL Preset',
      adjustments: ImageAdjustments.initial,
      hslColorMixer: presetMixer,
    );
    expect(controller.session.hslColorMixer, presetMixer);
    expect(controller.history.last.action, EditorHistoryAction.preset);
    controller.undo();
    expect(controller.session.hslColorMixer.green.saturation, 20);
    controller.redo();
    expect(controller.session.hslColorMixer, presetMixer);
  });

  test('preset without HSL resets existing HSL to neutral', () {
    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.setSourceImage('photo.jpg');
    controller.updateHslColorMixer(
      HslColorMixer.initial.withAdjustment(
        HslColorRange.red,
        HslColorAdjustment(hue: 25),
      ),
    );
    controller.applyPreset(
      presetId: 'legacy-preset',
      adjustments: ImageAdjustments.initial,
    );
    expect(controller.session.hslColorMixer, HslColorMixer.initial);
  });
}
