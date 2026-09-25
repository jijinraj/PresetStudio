import '../domain/preset.dart';
import '../domain/preset_record.dart';
import 'preset_library_store.dart';

class PresetLibraryException implements Exception {
  const PresetLibraryException(this.message);

  final String message;

  @override
  String toString() => 'PresetLibraryException: $message';
}

class PresetLibrary {
  PresetLibrary({required this.store, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final PresetLibraryStore store;
  final DateTime Function() _clock;

  Future<List<PresetRecord>> load() {
    return store.loadRecords();
  }

  Future<PresetRecord> saveLocal(Preset preset) async {
    final now = _clock().toUtc();
    final libraryId = PresetRecord.localLibraryId(preset.id);
    final existing = await _recordById(libraryId);

    if (existing != null && existing.origin.type != PresetOriginType.local) {
      throw PresetLibraryException(
        'Library record $libraryId is not a local preset.',
      );
    }

    final record = PresetRecord(
      libraryId: libraryId,
      preset: preset,
      origin: PresetOrigin.local(),
      installedAt: existing?.installedAt ?? now,
      updatedAt: now,
    );

    await store.upsertRecord(record);
    return record;
  }

  Future<PresetRecord> installRemote({
    required Preset preset,
    required String sourceId,
    String? remotePresetId,
    int? remoteRevision,
  }) async {
    final normalizedRemotePresetId = remotePresetId?.trim().isNotEmpty == true
        ? remotePresetId!.trim()
        : preset.id;
    final origin = PresetOrigin.remoteInstalled(
      sourceId: sourceId,
      remotePresetId: normalizedRemotePresetId,
      remoteRevision: remoteRevision,
    );
    final libraryId = PresetRecord.remoteLibraryId(
      sourceId: origin.sourceId!,
      remotePresetId: origin.remotePresetId!,
    );
    final now = _clock().toUtc();
    final existing = await _recordById(libraryId);

    final record = PresetRecord(
      libraryId: libraryId,
      preset: preset,
      origin: origin,
      installedAt: existing?.installedAt ?? now,
      updatedAt: now,
    );

    await store.upsertRecord(record);
    return record;
  }

  Future<PresetRecord> renameLocal(String libraryId, String newName) async {
    final existing = await _requireRecord(libraryId);

    if (!existing.origin.isMutable) {
      throw PresetLibraryException(
        'Only local presets can be renamed in place.',
      );
    }

    final updatedPreset = existing.preset.copyWith(
      name: newName,
      revision: existing.preset.revision + 1,
    );
    final updatedRecord = existing.copyWith(
      preset: updatedPreset,
      updatedAt: _clock().toUtc(),
    );

    await store.upsertRecord(updatedRecord);
    return updatedRecord;
  }

  Future<void> delete(String libraryId) async {
    final existing = await _requireRecord(libraryId);

    if (existing.origin.type == PresetOriginType.builtIn) {
      throw const PresetLibraryException('Built-in presets cannot be deleted.');
    }

    await store.deleteRecord(libraryId);
  }

  Future<PresetRecord?> _recordById(String libraryId) async {
    final records = await store.loadRecords();

    for (final record in records) {
      if (record.libraryId == libraryId) {
        return record;
      }
    }

    return null;
  }

  Future<PresetRecord> _requireRecord(String libraryId) async {
    final record = await _recordById(libraryId);

    if (record == null) {
      throw PresetLibraryException('Unknown preset record: $libraryId.');
    }

    return record;
  }
}
