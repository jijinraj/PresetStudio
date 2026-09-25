class PresetCatalogException implements Exception {
  const PresetCatalogException(this.message);

  final String message;

  @override
  String toString() => 'PresetCatalogException: $message';
}

class PresetCatalog {
  factory PresetCatalog({
    int schemaVersion = currentSchemaVersion,
    required String name,
    String? description,
    required Iterable<PresetCatalogEntry> presets,
  }) {
    final normalizedName = name.trim();
    final normalizedDescription = _normalizeOptional(description);
    final normalizedPresets = List<PresetCatalogEntry>.unmodifiable(presets);

    if (schemaVersion != currentSchemaVersion) {
      throw PresetCatalogException(
        'Unsupported catalog schemaVersion $schemaVersion. '
        'Expected $currentSchemaVersion.',
      );
    }

    if (normalizedName.isEmpty || normalizedName.length > 120) {
      throw const PresetCatalogException(
        'Catalog name must contain between 1 and 120 characters.',
      );
    }

    if (normalizedDescription != null && normalizedDescription.length > 1000) {
      throw const PresetCatalogException(
        'Catalog description cannot exceed 1000 characters.',
      );
    }

    final identities = <String>{};
    for (final preset in normalizedPresets) {
      if (!identities.add(preset.id)) {
        throw PresetCatalogException(
          'Duplicate catalog preset id: ${preset.id}.',
        );
      }
    }

    return PresetCatalog._(
      schemaVersion: schemaVersion,
      name: normalizedName,
      description: normalizedDescription,
      presets: normalizedPresets,
    );
  }

  const PresetCatalog._({
    required this.schemaVersion,
    required this.name,
    required this.description,
    required this.presets,
  });

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String name;
  final String? description;
  final List<PresetCatalogEntry> presets;
}

class PresetCatalogEntry {
  factory PresetCatalogEntry({
    required String id,
    required String name,
    String? author,
    required int revision,
    required String presetPath,
    String? previewPath,
  }) {
    final normalizedId = id.trim();
    final normalizedName = name.trim();
    final normalizedAuthor = _normalizeOptional(author);
    final normalizedPresetPath = _normalizeRelativePath(
      presetPath,
      fieldName: 'preset',
    );
    final normalizedPreviewPath = previewPath == null
        ? null
        : _normalizeRelativePath(previewPath, fieldName: 'preview');

    if (normalizedId.isEmpty || normalizedId.length > 128) {
      throw const PresetCatalogException(
        'Preset id must contain between 1 and 128 characters.',
      );
    }

    if (normalizedName.isEmpty || normalizedName.length > 120) {
      throw const PresetCatalogException(
        'Preset name must contain between 1 and 120 characters.',
      );
    }

    if (normalizedAuthor != null && normalizedAuthor.length > 120) {
      throw const PresetCatalogException(
        'Preset author cannot exceed 120 characters.',
      );
    }

    if (revision <= 0) {
      throw const PresetCatalogException(
        'Preset revision must be a positive integer.',
      );
    }

    return PresetCatalogEntry._(
      id: normalizedId,
      name: normalizedName,
      author: normalizedAuthor,
      revision: revision,
      presetPath: normalizedPresetPath,
      previewPath: normalizedPreviewPath,
    );
  }

  const PresetCatalogEntry._({
    required this.id,
    required this.name,
    required this.author,
    required this.revision,
    required this.presetPath,
    required this.previewPath,
  });

  final String id;
  final String name;
  final String? author;
  final int revision;
  final String presetPath;
  final String? previewPath;
}

String? _normalizeOptional(String? value) {
  final normalized = value?.trim();

  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return normalized;
}

String _normalizeRelativePath(String value, {required String fieldName}) {
  final normalized = value.trim().replaceAll(r'\', '/');
  final uri = Uri.tryParse(normalized);

  if (normalized.isEmpty ||
      normalized.startsWith('/') ||
      normalized.startsWith('./') ||
      uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.query.isNotEmpty ||
      uri.fragment.isNotEmpty) {
    throw PresetCatalogException(
      '$fieldName must be a repository-relative path.',
    );
  }

  final segments = normalized.split('/');

  if (segments.any(
    (segment) => segment.isEmpty || segment == '.' || segment == '..',
  )) {
    throw PresetCatalogException('$fieldName contains an unsafe path segment.');
  }

  return normalized;
}
