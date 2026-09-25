import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../domain/export_settings.dart';

class LocalImageExporter {
  const LocalImageExporter();

  Future<Uri?> saveImage({
    required Uint8List bytes,
    required ExportFormat format,
    required String sourceImagePath,
  }) {
    return FilePicker.saveFile(
      dialogTitle: 'Export image',
      fileName: suggestedFileName(
        sourceImagePath: sourceImagePath,
        format: format,
      ),
      bytes: bytes,
      mimeType: format.mimeType,
      type: FileType.custom,
      allowedExtensions: [format.fileExtension],
    );
  }

  static String suggestedFileName({
    required String sourceImagePath,
    required ExportFormat format,
  }) {
    final normalizedPath = sourceImagePath.replaceAll('\\', '/');
    final sourceName = normalizedPath.split('/').last;
    final extensionIndex = sourceName.lastIndexOf('.');
    final stem = extensionIndex > 0
        ? sourceName.substring(0, extensionIndex)
        : sourceName;
    final safeStem = stem.trim().isEmpty ? 'image' : stem.trim();

    return '${safeStem}_presetstudio.${format.fileExtension}';
  }
}
