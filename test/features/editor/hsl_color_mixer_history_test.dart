import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/domain/editor_session.dart';
import 'package:presetstudio/features/editor/domain/hsl_color_mixer.dart';

void main() {
  HslColorMixer modifiedMixer(double saturation) {
    return HslColorMixer.initial.withAdjustment(
      HslColorRange.blue,
      HslColorAdjustment(saturation: saturation),
    );
  }

  group('HSL Color Mixer editor state', () {
    test('editor session defaults to neutral HSL state', () {
      const session = EditorSession.initial;

      expect(session.hslColorMixer, HslColorMixer.initial);
      expect(session.hslColorMixer.isDefault, isTrue);
    });

    test('updating HSL marks session dirty and records history', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      controller.updateHslColorMixer(modifiedMixer(35));

      expect(controller.session.hslColorMixer.isDefault, isFalse);
      expect(controller.session.isDirty, isTrue);
      expect(controller.history, hasLength(2));
      expect(controller.history.last.label, 'HSL Color Mixer');
    });

    test('HSL updates clear the active preset', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      controller.applyPreset(
        presetId: 'preset-001',
        adjustments: controller.session.adjustments,
      );

      controller.updateHslColorMixer(modifiedMixer(35));

      expect(controller.session.activePresetId, isNull);
    });

    test('undo and redo restore HSL state', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      final mixer = modifiedMixer(35);
      controller.updateHslColorMixer(mixer);

      controller.undo();
      expect(controller.session.hslColorMixer, HslColorMixer.initial);
      expect(controller.session.isDirty, isFalse);

      controller.redo();
      expect(controller.session.hslColorMixer, mixer);
      expect(controller.session.isDirty, isTrue);
    });

    test('transaction groups HSL updates into one history entry', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      controller.beginEditTransaction();

      controller.updateHslColorMixer(modifiedMixer(20));
      controller.updateHslColorMixer(modifiedMixer(45));

      expect(controller.history, hasLength(1));

      controller.endEditTransaction();

      expect(controller.history, hasLength(2));
      expect(controller.history.last.label, 'HSL Color Mixer');
      expect(controller.session.hslColorMixer, modifiedMixer(45));
    });

    test('cancel transaction restores exact HSL state', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      final before = modifiedMixer(25);
      controller.updateHslColorMixer(before);

      controller.beginEditTransaction();
      controller.updateHslColorMixer(modifiedMixer(60));
      controller.cancelEditTransaction();

      expect(controller.session.hslColorMixer, before);
      expect(controller.history, hasLength(2));
    });

    test('disabling HSL history entries rebuilds structured state', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      controller.updateHslColorMixer(modifiedMixer(25));
      controller.updateHslColorMixer(modifiedMixer(55));

      controller.setHistoryEntryEnabled(1, false);
      expect(controller.session.hslColorMixer, modifiedMixer(55));

      controller.setHistoryEntryEnabled(2, false);
      expect(controller.session.hslColorMixer, HslColorMixer.initial);
    });

    test('setting a new source image resets HSL state', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('first.jpg');
      controller.updateHslColorMixer(modifiedMixer(35));

      controller.setSourceImage('second.jpg');

      expect(controller.session.hslColorMixer, HslColorMixer.initial);
      expect(controller.session.isDirty, isFalse);
    });

    test('mark saved includes HSL in dirty-state comparison', () {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('photo.jpg');
      final saved = modifiedMixer(35);
      controller.updateHslColorMixer(saved);
      controller.markSaved();

      expect(controller.session.isDirty, isFalse);

      controller.updateHslColorMixer(modifiedMixer(60));
      expect(controller.session.isDirty, isTrue);

      controller.updateHslColorMixer(saved);
      expect(controller.session.isDirty, isFalse);
    });
  });
}
