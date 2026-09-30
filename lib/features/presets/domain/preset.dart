import 'preset_adjustment_values.dart';
import 'preset_hsl_color_mixer_values.dart';
import 'preset_tone_curve_values.dart';

class PresetValidationException implements Exception {
  const PresetValidationException(this.message);

  final String message;

  @override
  String toString() => 'PresetValidationException: $message';
}

class Preset {
  factory Preset({
    int schemaVersion = currentSchemaVersion,
    required String id,
    required String name,
    String? description,
    String? author,
    required DateTime createdAt,
    int revision = 1,
    required PresetAdjustmentValues adjustments,
    PresetToneCurvesValues? toneCurves,
    PresetHslColorMixerValues? hslColorMixer,
  }) {
    final normalizedId = id.trim();
    final normalizedName = name.trim();
    final normalizedDescription = _normalizeOptional(description);
    final normalizedAuthor = _normalizeOptional(author);

    if (schemaVersion != currentSchemaVersion) {
      throw PresetValidationException(
        'Unsupported schemaVersion $schemaVersion. '
        'Expected $currentSchemaVersion.',
      );
    }

    if (normalizedId.isEmpty || normalizedId.length > 128) {
      throw const PresetValidationException(
        'id must contain between 1 and 128 characters.',
      );
    }

    if (normalizedName.isEmpty || normalizedName.length > 120) {
      throw const PresetValidationException(
        'name must contain between 1 and 120 characters.',
      );
    }

    if (normalizedDescription != null && normalizedDescription.length > 1000) {
      throw const PresetValidationException(
        'description cannot exceed 1000 characters.',
      );
    }

    if (normalizedAuthor != null && normalizedAuthor.length > 120) {
      throw const PresetValidationException(
        'author cannot exceed 120 characters.',
      );
    }

    if (revision <= 0) {
      throw const PresetValidationException(
        'revision must be a positive integer.',
      );
    }

    return Preset._(
      schemaVersion: schemaVersion,
      id: normalizedId,
      name: normalizedName,
      description: normalizedDescription,
      author: normalizedAuthor,
      createdAt: createdAt.toUtc(),
      revision: revision,
      adjustments: adjustments,
      toneCurves: toneCurves ?? PresetToneCurvesValues.initial,
      hslColorMixer: hslColorMixer ?? PresetHslColorMixerValues.initial,
    );
  }

  const Preset._({
    required this.schemaVersion,
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.createdAt,
    required this.revision,
    required this.adjustments,
    required this.toneCurves,
    required this.hslColorMixer,
  });

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String id;
  final String name;
  final String? description;
  final String? author;
  final DateTime createdAt;
  final int revision;
  final PresetAdjustmentValues adjustments;
  final PresetToneCurvesValues toneCurves;
  final PresetHslColorMixerValues hslColorMixer;

  Preset copyWith({
    String? name,
    String? description,
    bool clearDescription = false,
    String? author,
    bool clearAuthor = false,
    int? revision,
    PresetAdjustmentValues? adjustments,
    PresetToneCurvesValues? toneCurves,
    PresetHslColorMixerValues? hslColorMixer,
  }) {
    return Preset(
      schemaVersion: schemaVersion,
      id: id,
      name: name ?? this.name,
      description: clearDescription ? null : description ?? this.description,
      author: clearAuthor ? null : author ?? this.author,
      createdAt: createdAt,
      revision: revision ?? this.revision,
      adjustments: adjustments ?? this.adjustments,
      toneCurves: toneCurves ?? this.toneCurves,
      hslColorMixer: hslColorMixer ?? this.hslColorMixer,
    );
  }

  static String? _normalizeOptional(String? value) {
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Preset &&
            schemaVersion == other.schemaVersion &&
            id == other.id &&
            name == other.name &&
            description == other.description &&
            author == other.author &&
            createdAt == other.createdAt &&
            revision == other.revision &&
            adjustments == other.adjustments &&
            toneCurves == other.toneCurves &&
            hslColorMixer == other.hslColorMixer;
  }

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    id,
    name,
    description,
    author,
    createdAt,
    revision,
    adjustments,
    toneCurves,
    hslColorMixer,
  );
}
