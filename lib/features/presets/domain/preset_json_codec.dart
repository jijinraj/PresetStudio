import 'dart:convert';

import 'preset.dart';
import 'preset_adjustment_values.dart';

class PresetFormatException implements Exception {
  const PresetFormatException(this.message);

  final String message;

  @override
  String toString() => 'PresetFormatException: $message';
}

class PresetJsonCodec {
  const PresetJsonCodec();

  static const String format = 'presetstudio.preset';
  static const String fileSuffix = '.presetstudio.json';

  String encode(Preset preset) {
    final json = <String, Object?>{
      'format': format,
      'schemaVersion': preset.schemaVersion,
      'id': preset.id,
      'name': preset.name,
      if (preset.description != null) 'description': preset.description,
      if (preset.author != null) 'author': preset.author,
      'createdAt': preset.createdAt.toUtc().toIso8601String(),
      'revision': preset.revision,
      'adjustments': _encodeAdjustments(preset.adjustments),
    };

    return JsonEncoder.withIndent('  ').convert(json);
  }

  Preset decode(String source) {
    final Object? decoded;

    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw PresetFormatException('Invalid JSON: ${error.message}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const PresetFormatException(
        'Preset JSON must contain an object at the top level.',
      );
    }

    return decodeMap(decoded);
  }

  Preset decodeMap(Map<String, dynamic> json) {
    final presetFormat = _requiredString(json, 'format');

    if (presetFormat != format) {
      throw PresetFormatException('Unsupported preset format $presetFormat.');
    }

    final schemaVersion = _requiredInt(json, 'schemaVersion');

    if (schemaVersion != Preset.currentSchemaVersion) {
      throw PresetFormatException(
        'Unsupported preset schema version $schemaVersion. '
        'Supported version: ${Preset.currentSchemaVersion}.',
      );
    }

    final createdAtText = _requiredString(json, 'createdAt');
    final createdAt = DateTime.tryParse(createdAtText);

    if (createdAt == null) {
      throw const PresetFormatException(
        'createdAt must be a valid ISO-8601 timestamp.',
      );
    }

    final adjustmentsJson = json['adjustments'];

    if (adjustmentsJson is! Map<String, dynamic>) {
      throw const PresetFormatException('adjustments must be a JSON object.');
    }

    try {
      return Preset(
        schemaVersion: schemaVersion,
        id: _requiredString(json, 'id'),
        name: _requiredString(json, 'name'),
        description: _optionalString(json, 'description'),
        author: _optionalString(json, 'author'),
        createdAt: createdAt,
        revision: _requiredInt(json, 'revision'),
        adjustments: _decodeAdjustments(adjustmentsJson),
      );
    } on PresetValidationException catch (error) {
      throw PresetFormatException(error.message);
    }
  }

  Map<String, Object?> _encodeAdjustments(PresetAdjustmentValues values) {
    return <String, Object?>{
      'exposure': values.exposure,
      'contrast': values.contrast,
      'highlights': values.highlights,
      'shadows': values.shadows,
      'whites': values.whites,
      'blacks': values.blacks,
      'temperature': values.temperature,
      'tint': values.tint,
      'vibrance': values.vibrance,
      'saturation': values.saturation,
      'vignetteAmount': values.vignetteAmount,
      'vignetteFeather': values.vignetteFeather,
    };
  }

  PresetAdjustmentValues _decodeAdjustments(Map<String, dynamic> json) {
    return PresetAdjustmentValues(
      exposure: _requiredDouble(json, 'exposure'),
      contrast: _requiredDouble(json, 'contrast'),
      highlights: _requiredDouble(json, 'highlights'),
      shadows: _requiredDouble(json, 'shadows'),
      whites: _requiredDouble(json, 'whites'),
      blacks: _requiredDouble(json, 'blacks'),
      temperature: _requiredDouble(json, 'temperature'),
      tint: _requiredDouble(json, 'tint'),
      vibrance: _requiredDouble(json, 'vibrance'),
      saturation: _requiredDouble(json, 'saturation'),
      vignetteAmount: _optionalDouble(json, 'vignetteAmount') ?? 0,
      vignetteFeather: _optionalDouble(json, 'vignetteFeather') ?? 50,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw PresetFormatException('$key must be a non-empty string.');
    }

    return value;
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    if (!json.containsKey(key) || json[key] == null) {
      return null;
    }

    final value = json[key];

    if (value is! String) {
      throw PresetFormatException('$key must be a string when provided.');
    }

    return value;
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! int) {
      throw PresetFormatException('$key must be an integer.');
    }

    return value;
  }

  static double? _optionalDouble(Map<String, dynamic> json, String key) {
    if (!json.containsKey(key) || json[key] == null) {
      return null;
    }

    return _requiredDouble(json, key);
  }

  static double _requiredDouble(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! num) {
      throw PresetFormatException('$key must be numeric.');
    }

    final result = value.toDouble();

    if (!result.isFinite) {
      throw PresetFormatException('$key must be finite.');
    }

    return result;
  }
}
