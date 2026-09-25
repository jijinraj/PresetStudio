import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:presetstudio/features/editor/domain/crop_state.dart';
import 'package:presetstudio/features/editor/domain/editor_session.dart';
import 'package:presetstudio/features/editor/domain/export_settings.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/editor/domain/image_transform.dart';
import 'package:presetstudio/features/editor/rendering/export_image_renderer.dart';

void main() {
  const renderer = ExportImageRenderer();

  Uint8List pngSource(img.Image image) {
    return img.encodePng(image);
  }

  img.Image decode(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    expect(decoded, isNotNull);
    return decoded!;
  }

  test('renders untouched source at original pixel dimensions', () {
    final source = img.Image(width: 3, height: 2, numChannels: 4)
      ..setPixelRgba(0, 0, 255, 0, 0, 255)
      ..setPixelRgba(1, 0, 0, 255, 0, 255)
      ..setPixelRgba(2, 0, 0, 0, 255, 255)
      ..setPixelRgba(0, 1, 255, 255, 0, 255)
      ..setPixelRgba(1, 1, 0, 255, 255, 255)
      ..setPixelRgba(2, 1, 255, 0, 255, 255);

    final result = renderer.render(
      sourceBytes: pngSource(source),
      session: const EditorSession(
        sourceImagePath: 'source.png',
        exportSettings: ExportSettings(format: ExportFormat.png),
      ),
    );

    final output = decode(result.bytes);

    expect(result.plan.outputWidth, 3);
    expect(result.plan.outputHeight, 2);
    expect(output.width, 3);
    expect(output.height, 2);

    final first = output.getPixel(0, 0);
    final last = output.getPixel(2, 1);

    expect(first.r, 255);
    expect(first.g, 0);
    expect(first.b, 0);
    expect(last.r, 255);
    expect(last.g, 0);
    expect(last.b, 255);
  });

  test('replays horizontal flip into exported pixels', () {
    final source = img.Image(width: 2, height: 1, numChannels: 4)
      ..setPixelRgba(0, 0, 255, 0, 0, 255)
      ..setPixelRgba(1, 0, 0, 0, 255, 255);

    final result = renderer.render(
      sourceBytes: pngSource(source),
      session: const EditorSession(
        sourceImagePath: 'source.png',
        transform: ImageTransform(flipHorizontal: true),
        exportSettings: ExportSettings(format: ExportFormat.png),
      ),
    );

    final output = decode(result.bytes);

    expect(output.getPixel(0, 0).b, 255);
    expect(output.getPixel(1, 0).r, 255);
  });

  test('rotation uses planned full-resolution bounds', () {
    final source = img.Image(width: 3, height: 2, numChannels: 4);

    final result = renderer.render(
      sourceBytes: pngSource(source),
      session: const EditorSession(
        sourceImagePath: 'source.png',
        transform: ImageTransform(rotationDegrees: 90),
        exportSettings: ExportSettings(format: ExportFormat.png),
      ),
    );

    final output = decode(result.bytes);

    expect(result.plan.fullResolutionWidth, 2);
    expect(result.plan.fullResolutionHeight, 3);
    expect(output.width, 2);
    expect(output.height, 3);
  });

  test('committed crop exports at crop-frame dimensions', () {
    final source = img.Image(width: 4, height: 2, numChannels: 4);

    final result = renderer.render(
      sourceBytes: pngSource(source),
      session: const EditorSession(
        sourceImagePath: 'source.png',
        crop: CropState(
          normalizedRect: NormalizedCropRect(
            left: 0.25,
            top: 0,
            right: 0.75,
            bottom: 1,
          ),
          aspectRatio: 1,
        ),
        exportSettings: ExportSettings(format: ExportFormat.png),
      ),
    );

    final output = decode(result.bytes);

    expect(result.plan.fullResolutionWidth, 2);
    expect(result.plan.fullResolutionHeight, 2);
    expect(output.width, 2);
    expect(output.height, 2);
  });

  test('longest-edge limit renders directly at planned dimensions', () {
    final source = img.Image(width: 8, height: 4, numChannels: 4);

    final result = renderer.render(
      sourceBytes: pngSource(source),
      session: const EditorSession(
        sourceImagePath: 'source.png',
        exportSettings: ExportSettings(
          format: ExportFormat.png,
          resolutionMode: ExportResolutionMode.maxDimension,
          maxDimension: 4,
        ),
      ),
    );

    final output = decode(result.bytes);

    expect(result.plan.isDownscaled, isTrue);
    expect(output.width, 4);
    expect(output.height, 2);
  });

  test('applies adjustments while rendering source pixels', () {
    final source = img.Image(width: 1, height: 1, numChannels: 4)
      ..setPixelRgba(0, 0, 64, 32, 16, 255);

    final result = renderer.render(
      sourceBytes: pngSource(source),
      session: const EditorSession(
        sourceImagePath: 'source.png',
        adjustments: ImageAdjustments(exposure: 1),
        exportSettings: ExportSettings(format: ExportFormat.png),
      ),
    );

    final pixel = decode(result.bytes).getPixel(0, 0);

    expect(pixel.r, closeTo(128, 1));
    expect(pixel.g, closeTo(64, 1));
    expect(pixel.b, closeTo(32, 1));
  });

  test('encodes JPEG at the planned dimensions', () {
    final source = img.Image(width: 5, height: 3, numChannels: 4)
      ..clear(img.ColorRgba8(80, 120, 160, 255));

    final result = renderer.render(
      sourceBytes: pngSource(source),
      session: const EditorSession(
        sourceImagePath: 'source.png',
        exportSettings: ExportSettings(format: ExportFormat.jpeg, quality: 87),
      ),
    );

    final output = decode(result.bytes);

    expect(result.plan.format, ExportFormat.jpeg);
    expect(result.plan.quality, 87);
    expect(output.width, 5);
    expect(output.height, 3);
  });

  test('encodes lossy WebP at the planned dimensions', () {
    final source = img.Image(width: 5, height: 3, numChannels: 4)
      ..clear(img.ColorRgba8(80, 120, 160, 255));

    final result = renderer.render(
      sourceBytes: pngSource(source),
      session: const EditorSession(
        sourceImagePath: 'source.png',
        exportSettings: ExportSettings(format: ExportFormat.webp, quality: 79),
      ),
    );

    final output = decode(result.bytes);

    expect(result.plan.format, ExportFormat.webp);
    expect(result.plan.quality, 79);
    expect(output.width, 5);
    expect(output.height, 3);
  });

  test('rejects undecodable source bytes', () {
    expect(
      () => renderer.render(
        sourceBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        session: const EditorSession(sourceImagePath: 'broken.bin'),
      ),
      throwsA(isA<ExportImageRenderException>()),
    );
  });
}
