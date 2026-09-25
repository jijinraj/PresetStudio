import 'dart:convert';

import 'preset.dart';

enum PresetOriginType { builtIn, local, remoteInstalled }

class PresetRecordValidationException implements Exception {
  const PresetRecordValidationException(this.message);

  final String message;

  @override
  String toString() => 'PresetRecordValidationException: $message';
}

class PresetOrigin {
  factory PresetOrigin.local() {
    return const PresetOrigin._(type: PresetOriginType.local);
  }

  factory PresetOrigin.builtIn() {
    return const PresetOrigin._(type: PresetOriginType.builtIn);
  }

  factory PresetOrigin.remoteInstalled({
    required String sourceId,
    required String remotePresetId,
    int? remoteRevision,
  }) {
    final normalizedSourceId = sourceId.trim();
    final normalizedRemotePresetId = remotePresetId.trim();

    if (normalizedSourceId.isEmpty || normalizedSourceId.length > 128) {
      throw const PresetRecordValidationException(
        'sourceId must contain between 1 and 128 characters.',
      );
    }

    if (normalizedRemotePresetId.isEmpty ||
        normalizedRemotePresetId.length > 128) {
      throw const PresetRecordValidationException(
        'remotePresetId must contain between 1 and 128 characters.',
      );
    }

    if (remoteRevision != null && remoteRevision <= 0) {
      throw const PresetRecordValidationException(
        'remoteRevision must be a positive integer when provided.',
      );
    }

    return PresetOrigin._(
      type: PresetOriginType.remoteInstalled,
      sourceId: normalizedSourceId,
      remotePresetId: normalizedRemotePresetId,
      remoteRevision: remoteRevision,
    );
  }

  const PresetOrigin._({
    required this.type,
    this.sourceId,
    this.remotePresetId,
    this.remoteRevision,
  });

  final PresetOriginType type;
  final String? sourceId;
  final String? remotePresetId;
  final int? remoteRevision;

  bool get isMutable => type == PresetOriginType.local;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PresetOrigin &&
            type == other.type &&
            sourceId == other.sourceId &&
            remotePresetId == other.remotePresetId &&
            remoteRevision == other.remoteRevision;
  }

  @override
  int get hashCode =>
      Object.hash(type, sourceId, remotePresetId, remoteRevision);
}

class PresetRecord {
  factory PresetRecord({
    required String libraryId,
    required Preset preset,
    required PresetOrigin origin,
    required DateTime installedAt,
    required DateTime updatedAt,
  }) {
    final normalizedLibraryId = libraryId.trim();
    final installedAtUtc = installedAt.toUtc();
    final updatedAtUtc = updatedAt.toUtc();

    if (normalizedLibraryId.isEmpty || normalizedLibraryId.length > 512) {
      throw const PresetRecordValidationException(
        'libraryId must contain between 1 and 512 characters.',
      );
    }

    if (updatedAtUtc.isBefore(installedAtUtc)) {
      throw const PresetRecordValidationException(
        'updatedAt cannot be earlier than installedAt.',
      );
    }

    return PresetRecord._(
      libraryId: normalizedLibraryId,
      preset: preset,
      origin: origin,
      installedAt: installedAtUtc,
      updatedAt: updatedAtUtc,
    );
  }

  const PresetRecord._({
    required this.libraryId,
    required this.preset,
    required this.origin,
    required this.installedAt,
    required this.updatedAt,
  });

  final String libraryId;
  final Preset preset;
  final PresetOrigin origin;
  final DateTime installedAt;
  final DateTime updatedAt;

  static String localLibraryId(String presetId) {
    return _libraryId('local', [presetId]);
  }

  static String builtInLibraryId(String presetId) {
    return _libraryId('builtin', [presetId]);
  }

  static String remoteLibraryId({
    required String sourceId,
    required String remotePresetId,
  }) {
    return _libraryId('remote', [sourceId, remotePresetId]);
  }

  PresetRecord copyWith({
    Preset? preset,
    PresetOrigin? origin,
    DateTime? updatedAt,
  }) {
    return PresetRecord(
      libraryId: libraryId,
      preset: preset ?? this.preset,
      origin: origin ?? this.origin,
      installedAt: installedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _libraryId(String prefix, List<String> components) {
    final encoded = components.map((component) {
      return base64Url
          .encode(utf8.encode(component.trim()))
          .replaceAll('=', '');
    });

    return ([prefix, ...encoded]).join('.');
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PresetRecord &&
            libraryId == other.libraryId &&
            preset == other.preset &&
            origin == other.origin &&
            installedAt == other.installedAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode =>
      Object.hash(libraryId, preset, origin, installedAt, updatedAt);
}
