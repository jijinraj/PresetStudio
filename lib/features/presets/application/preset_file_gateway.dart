import '../domain/preset.dart';

class PresetFileException implements Exception {
  const PresetFileException(this.message);

  final String message;

  @override
  String toString() => 'PresetFileException: $message';
}

abstract interface class PresetFileGateway {
  Future<Preset?> importPreset();

  Future<Uri?> exportPreset(Preset preset);
}
