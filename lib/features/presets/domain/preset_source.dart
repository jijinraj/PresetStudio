enum PresetSourceKind { repository, catalog }

class PresetSourceException implements Exception {
  const PresetSourceException(this.message);

  final String message;

  @override
  String toString() => 'PresetSourceException: $message';
}

class PresetRemoteSource {
  factory PresetRemoteSource({
    required String id,
    required String name,
    required PresetSourceKind kind,
    required String location,
    bool enabled = true,
  }) {
    final normalizedId = id.trim();
    final normalizedName = name.trim();
    final normalizedLocation = location.trim();
    final uri = Uri.tryParse(normalizedLocation);

    if (normalizedId.isEmpty || normalizedId.length > 128) {
      throw const PresetSourceException(
        'Source id must contain between 1 and 128 characters.',
      );
    }

    if (normalizedName.isEmpty || normalizedName.length > 120) {
      throw const PresetSourceException(
        'Source name must contain between 1 and 120 characters.',
      );
    }

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      throw const PresetSourceException(
        'Source location must be an absolute HTTP or HTTPS URL.',
      );
    }

    return PresetRemoteSource._(
      id: normalizedId,
      name: normalizedName,
      kind: kind,
      location: uri,
      enabled: enabled,
    );
  }

  const PresetRemoteSource._({
    required this.id,
    required this.name,
    required this.kind,
    required this.location,
    required this.enabled,
  });

  final String id;
  final String name;
  final PresetSourceKind kind;
  final Uri location;
  final bool enabled;

  String get canonicalLocation {
    final withoutFragment = location.toString().split('#').first;

    if (withoutFragment.endsWith('/')) {
      return withoutFragment.substring(0, withoutFragment.length - 1);
    }

    return withoutFragment;
  }

  PresetRemoteSource copyWith({
    String? name,
    PresetSourceKind? kind,
    String? location,
    bool? enabled,
  }) {
    return PresetRemoteSource(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      location: location ?? this.location.toString(),
      enabled: enabled ?? this.enabled,
    );
  }
}

class PresetSourceRegistry {
  PresetSourceRegistry({Iterable<PresetRemoteSource> sources = const []})
    : sources = List<PresetRemoteSource>.unmodifiable(sources) {
    _validateUnique(this.sources);
  }

  final List<PresetRemoteSource> sources;

  PresetRemoteSource? sourceById(String id) {
    for (final source in sources) {
      if (source.id == id) {
        return source;
      }
    }

    return null;
  }

  PresetSourceRegistry add(PresetRemoteSource source) {
    return PresetSourceRegistry(
      sources: <PresetRemoteSource>[...sources, source],
    );
  }

  PresetSourceRegistry remove(String sourceId) {
    return PresetSourceRegistry(
      sources: sources.where((source) => source.id != sourceId),
    );
  }

  PresetSourceRegistry replace(PresetRemoteSource source) {
    if (sourceById(source.id) == null) {
      throw PresetSourceException('Unknown preset source: ${source.id}.');
    }

    return PresetSourceRegistry(
      sources: sources.map(
        (existing) => existing.id == source.id ? source : existing,
      ),
    );
  }

  PresetSourceRegistry setEnabled(String sourceId, bool enabled) {
    final source = sourceById(sourceId);

    if (source == null) {
      throw PresetSourceException('Unknown preset source: $sourceId.');
    }

    return replace(source.copyWith(enabled: enabled));
  }

  static void _validateUnique(List<PresetRemoteSource> sources) {
    final ids = <String>{};
    final locations = <String>{};

    for (final source in sources) {
      if (!ids.add(source.id)) {
        throw PresetSourceException(
          'Duplicate preset source id: ${source.id}.',
        );
      }

      if (!locations.add(source.canonicalLocation)) {
        throw PresetSourceException(
          'Duplicate preset source location: ${source.location}.',
        );
      }
    }
  }
}
