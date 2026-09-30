import 'dart:convert';

import 'preset.dart';
import 'preset_adjustment_values.dart';
import 'preset_hsl_color_mixer_values.dart';
import 'preset_tone_curve_values.dart';

class PresetFormatException implements Exception {
  const PresetFormatException(this.message);

  final String message;

  @override
  String toString() => 'PresetFormatException: $message';
}

class PresetJsonCodec {
  const PresetJsonCodec();

  static const String format = 'presetstudio.preset';
  static const String fileSuffix = '.presetstudio';

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
      'toneCurves': _encodeToneCurves(preset.toneCurves),
      'hslColorMixer': _encodeHslColorMixer(preset.hslColorMixer),
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
        toneCurves: _decodeToneCurves(json['toneCurves']),
        hslColorMixer: _decodeHslColorMixer(json['hslColorMixer']),
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

  Map<String, Object?> _encodeHslColorMixer(PresetHslColorMixerValues mixer) {
    return <String, Object?>{
      'red': _encodeHslAdjustment(mixer.red),
      'orange': _encodeHslAdjustment(mixer.orange),
      'yellow': _encodeHslAdjustment(mixer.yellow),
      'green': _encodeHslAdjustment(mixer.green),
      'aqua': _encodeHslAdjustment(mixer.aqua),
      'blue': _encodeHslAdjustment(mixer.blue),
      'purple': _encodeHslAdjustment(mixer.purple),
      'magenta': _encodeHslAdjustment(mixer.magenta),
    };
  }

  Map<String, double> _encodeHslAdjustment(
    PresetHslColorAdjustmentValues adjustment,
  ) {
    return <String, double>{
      'hue': adjustment.hue,
      'saturation': adjustment.saturation,
      'luminance': adjustment.luminance,
    };
  }

  PresetHslColorMixerValues _decodeHslColorMixer(Object? value) {
    if (value == null) {
      return PresetHslColorMixerValues.initial;
    }
    if (value is! Map<String, dynamic>) {
      throw const PresetFormatException('hslColorMixer must be a JSON object.');
    }

    return PresetHslColorMixerValues(
      red: _decodeHslAdjustment(value, 'red'),
      orange: _decodeHslAdjustment(value, 'orange'),
      yellow: _decodeHslAdjustment(value, 'yellow'),
      green: _decodeHslAdjustment(value, 'green'),
      aqua: _decodeHslAdjustment(value, 'aqua'),
      blue: _decodeHslAdjustment(value, 'blue'),
      purple: _decodeHslAdjustment(value, 'purple'),
      magenta: _decodeHslAdjustment(value, 'magenta'),
    );
  }

  PresetHslColorAdjustmentValues _decodeHslAdjustment(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is! Map<String, dynamic>) {
      throw PresetFormatException('hslColorMixer.$key must be a JSON object.');
    }

    return PresetHslColorAdjustmentValues(
      hue: _requiredDouble(value, 'hue'),
      saturation: _requiredDouble(value, 'saturation'),
      luminance: _requiredDouble(value, 'luminance'),
    );
  }

  Map<String, Object?> _encodeToneCurves(PresetToneCurvesValues curves) {
    return <String, Object?>{
      'master': _encodeToneCurve(curves.master),
      'red': _encodeToneCurve(curves.red),
      'green': _encodeToneCurve(curves.green),
      'blue': _encodeToneCurve(curves.blue),
    };
  }

  List<Map<String, double>> _encodeToneCurve(PresetToneCurveValues curve) {
    return curve.points
        .map(
          (point) => <String, double>{
            'input': point.input,
            'output': point.output,
          },
        )
        .toList(growable: false);
  }

  PresetToneCurvesValues _decodeToneCurves(Object? value) {
    if (value == null) {
      return PresetToneCurvesValues.initial;
    }
    if (value is! Map<String, dynamic>) {
      throw const PresetFormatException('toneCurves must be a JSON object.');
    }
    return PresetToneCurvesValues(
      master: _decodeToneCurve(value, 'master'),
      red: _decodeToneCurve(value, 'red'),
      green: _decodeToneCurve(value, 'green'),
      blue: _decodeToneCurve(value, 'blue'),
    );
  }

  PresetToneCurveValues _decodeToneCurve(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is! List) {
      throw PresetFormatException('toneCurves.$key must be a JSON array.');
    }
    final points = <PresetCurvePointValues>[];
    for (var index = 0; index < value.length; index += 1) {
      final point = value[index];
      if (point is! Map<String, dynamic>) {
        throw PresetFormatException(
          'toneCurves.$key[$index] must be a JSON object.',
        );
      }
      points.add(
        PresetCurvePointValues(
          input: _requiredDouble(point, 'input'),
          output: _requiredDouble(point, 'output'),
        ),
      );
    }
    return PresetToneCurveValues(points: points);
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
