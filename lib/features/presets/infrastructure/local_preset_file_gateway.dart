import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../application/preset_file_gateway.dart';
import '../domain/preset.dart';
import '../domain/preset_json_codec.dart';

class LocalPresetFileGateway implements PresetFileGateway {
  const LocalPresetFileGateway({this.codec = const PresetJsonCodec()});

  final PresetJsonCodec codec;

  @override
  Future<Preset?> importPreset() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );

    if (file == null) {
      return null;
    }

    final path = file.path;

    if (path == null || path.trim().isEmpty) {
      throw const PresetFileException(
        'The selected preset is not available as a local file.',
      );
    }

    final String source;

    try {
      source = await File(path).readAsString();
    } on FileSystemException catch (error) {
      throw PresetFileException(
        'The selected preset could not be read: ${error.message}',
      );
    } on FormatException {
      throw const PresetFileException(
        'The selected preset is not valid UTF-8 text.',
      );
    }

    return codec.decode(source);
  }

  @override
  Future<Uri?> exportPreset(Preset preset) {
    final bytes = Uint8List.fromList(utf8.encode(codec.encode(preset)));

    return FilePicker.saveFile(
      dialogTitle: 'Export preset',
      fileName: suggestedFileName(preset),
      bytes: bytes,
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
  }

  static String suggestedFileName(Preset preset) {
    var stem = preset.name
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[. ]+$'), '')
        .trim();

    if (stem.isEmpty) {
      stem = 'preset';
    }

    if (stem.length > 80) {
      stem = stem.substring(0, 80).replaceAll(RegExp(r'[. ]+$'), '').trim();
    }

    return '$stem${PresetJsonCodec.fileSuffix}';
  }
}
