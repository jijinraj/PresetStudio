import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:presetstudio/features/editor/domain/editor_session.dart';
import 'package:presetstudio/features/editor/domain/export_settings.dart';
import 'package:presetstudio/features/editor/domain/hsl_color_mixer.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/editor/rendering/export_image_renderer.dart';
import 'package:presetstudio/features/editor/rendering/export_tonal_processor.dart';

void main() {
  test('full-resolution export replays HSL color mixer state', () {
    final source = img.Image(width: 1, height: 1, numChannels: 4)
      ..setPixelRgba(0, 0, 204, 77, 77, 255);

    final mixer = HslColorMixer.initial.withAdjustment(
      HslColorRange.red,
      HslColorAdjustment(saturation: 60, luminance: -15),
    );

    final result = const ExportImageRenderer().render(
      sourceBytes: Uint8List.fromList(img.encodePng(source)),
      session: EditorSession(
        sourceImagePath: 'source.png',
        hslColorMixer: mixer,
        exportSettings: const ExportSettings(format: ExportFormat.png),
      ),
    );

    final output = img.decodeImage(result.bytes);
    expect(output, isNotNull);

    final pixel = output!.getPixel(0, 0);
    final expected = ExportTonalProcessor(
      ImageAdjustments.initial,
      hslColorMixer: mixer,
    ).apply(204 / 255, 77 / 255, 77 / 255);

    expect(pixel.r, closeTo(expected.$1 * 255, 1));
    expect(pixel.g, closeTo(expected.$2 * 255, 1));
    expect(pixel.b, closeTo(expected.$3 * 255, 1));
  });
}
