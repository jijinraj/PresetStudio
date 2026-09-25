import '../domain/preset_record.dart';

abstract interface class PresetLibraryStore {
  Future<List<PresetRecord>> loadRecords();

  Future<void> upsertRecord(PresetRecord record);

  Future<void> deleteRecord(String libraryId);
}
