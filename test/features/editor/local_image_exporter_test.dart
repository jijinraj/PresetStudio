import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/export_settings.dart';
import 'package:presetstudio/features/editor/infrastructure/local_image_exporter.dart';

void main() {
  group('LocalImageExporter.suggestedFileName', () {
    test('uses source stem and selected export extension', () {
      expect(
        LocalImageExporter.suggestedFileName(
          sourceImagePath: r'C:\Photos\flower.edit.jpeg',
          format: ExportFormat.webp,
        ),
        'flower.edit_presetstudio.webp',
      );

      expect(
        LocalImageExporter.suggestedFileName(
          sourceImagePath: '/photos/portrait.png',
          format: ExportFormat.jpeg,
        ),
        'portrait_presetstudio.jpg',
      );
    });
  });
}
