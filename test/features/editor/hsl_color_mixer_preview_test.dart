import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/hsl_color_mixer.dart';

void main() {
  HslColorMixer modifiedMixer() {
    return HslColorMixer.initial.withAdjustment(
      HslColorRange.orange,
      HslColorAdjustment(hue: 20, saturation: 30, luminance: -10),
    );
  }

  test('HSL-only edits enable before comparison and reset', () {
    final controller = EditorController();
    addTearDown(controller.dispose);

    controller.setSourceImage('photo.jpg');
    controller.updateHslColorMixer(modifiedMixer());

    expect(controller.canCompareBefore, isTrue);
    expect(controller.canResetAdjustments, isTrue);

    controller.resetAdjustments();

    expect(controller.session.hslColorMixer, HslColorMixer.initial);
    expect(controller.canCompareBefore, isFalse);
  });

  test('before preview uses neutral HSL and restores edited state', () {
    final controller = EditorController();
    addTearDown(controller.dispose);

    controller.setSourceImage('photo.jpg');
    final mixer = modifiedMixer();
    controller.updateHslColorMixer(mixer);

    expect(controller.previewHslColorMixer, mixer);

    controller.beginBeforePreview();
    expect(controller.previewHslColorMixer, HslColorMixer.initial);

    controller.endBeforePreview();
    expect(controller.previewHslColorMixer, mixer);
  });
}
