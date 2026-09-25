import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/export_settings.dart';

void main() {
  group('ExportSettings', () {
    test('defaults to full-resolution JPEG at quality 92', () {
      const settings = ExportSettings.initial;

      expect(settings.format, ExportFormat.jpeg);
      expect(settings.quality, 92);
      expect(settings.resolutionMode, ExportResolutionMode.original);
      expect(settings.maxDimension, 2048);
      expect(settings.usesQuality, isTrue);
    });

    test('format metadata covers JPEG PNG and WebP', () {
      expect(ExportFormat.jpeg.label, 'JPEG');
      expect(ExportFormat.jpeg.fileExtension, 'jpg');
      expect(ExportFormat.jpeg.mimeType, 'image/jpeg');
      expect(ExportFormat.jpeg.supportsQuality, isTrue);

      expect(ExportFormat.png.label, 'PNG');
      expect(ExportFormat.png.fileExtension, 'png');
      expect(ExportFormat.png.mimeType, 'image/png');
      expect(ExportFormat.png.supportsQuality, isFalse);

      expect(ExportFormat.webp.label, 'WebP');
      expect(ExportFormat.webp.fileExtension, 'webp');
      expect(ExportFormat.webp.mimeType, 'image/webp');
      expect(ExportFormat.webp.supportsQuality, isTrue);
    });

    test('sanitized clamps quality and max dimension', () {
      const settings = ExportSettings(
        quality: 1000,
        resolutionMode: ExportResolutionMode.maxDimension,
        maxDimension: -20,
      );

      final sanitized = settings.sanitized();

      expect(sanitized.quality, ExportSettings.maximumQuality);
      expect(sanitized.maxDimension, ExportSettings.minimumMaxDimension);
    });

    test('copyWith retains unrelated export preferences', () {
      const settings = ExportSettings(
        format: ExportFormat.webp,
        quality: 84,
        resolutionMode: ExportResolutionMode.maxDimension,
        maxDimension: 4096,
      );

      final changed = settings.copyWith(format: ExportFormat.png);

      expect(changed.format, ExportFormat.png);
      expect(changed.quality, 84);
      expect(changed.resolutionMode, ExportResolutionMode.maxDimension);
      expect(changed.maxDimension, 4096);
    });
  });
}
