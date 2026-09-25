import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../editor/domain/image_adjustments.dart';
import '../domain/preset.dart';
import '../domain/preset_record.dart';
import 'preset_adjustment_mapper.dart';
import 'preset_library.dart';

typedef PresetLibraryLoader = Future<PresetLibrary> Function();
typedef PresetIdGenerator = String Function();

class PresetLibraryController extends ChangeNotifier {
  PresetLibraryController({
    required PresetLibraryLoader libraryLoader,
    PresetIdGenerator? idGenerator,
    DateTime Function()? clock,
  }) : this._(
         libraryLoader,
         idGenerator ?? _defaultPresetId,
         clock ?? DateTime.now,
       );

  PresetLibraryController._(
    this._libraryLoader,
    this._idGenerator,
    this._clock,
  );

  final PresetLibraryLoader _libraryLoader;
  final PresetIdGenerator _idGenerator;
  final DateTime Function() _clock;

  PresetLibrary? _library;
  List<PresetRecord> _records = const <PresetRecord>[];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isDisposed = false;

  List<PresetRecord> get records => List<PresetRecord>.unmodifiable(_records);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isReady => _library != null && !_isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_isLoading || _isInitialized) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();

    try {
      final library = await _libraryLoader();
      final records = await library.load();

      _library = library;
      _records = records;
      _isInitialized = true;
    } on Object catch (error) {
      _errorMessage = 'Preset library could not be loaded: $error';
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<void> retryInitialize() async {
    _isInitialized = false;
    await initialize();
  }

  Future<PresetRecord> saveCurrent({
    required String name,
    String? description,
    String? author,
    required ImageAdjustments adjustments,
  }) async {
    final library = _requireLibrary();
    final preset = Preset(
      id: _idGenerator(),
      name: name,
      description: description,
      author: author,
      createdAt: _clock().toUtc(),
      adjustments: PresetAdjustmentMapper.fromImageAdjustments(adjustments),
    );

    try {
      final record = await library.saveLocal(preset);
      _upsertRecord(record);
      _errorMessage = null;
      _notifyListeners();
      return record;
    } on Object catch (error) {
      _rememberMutationError(error);
      rethrow;
    }
  }

  PresetRecord? localRecordForPresetId(String presetId) {
    final normalizedPresetId = presetId.trim();

    for (final record in _records) {
      if (record.origin.type == PresetOriginType.local &&
          record.preset.id == normalizedPresetId) {
        return record;
      }
    }

    return null;
  }

  Future<PresetRecord> importPortablePreset(
    Preset preset, {
    bool asCopy = false,
  }) async {
    final library = _requireLibrary();
    final sanitizedAdjustments = PresetAdjustmentMapper.fromImageAdjustments(
      PresetAdjustmentMapper.toImageAdjustments(preset.adjustments),
    );
    final importedPreset = Preset(
      schemaVersion: preset.schemaVersion,
      id: asCopy ? _idGenerator() : preset.id,
      name: preset.name,
      description: preset.description,
      author: preset.author,
      createdAt: preset.createdAt,
      revision: preset.revision,
      adjustments: sanitizedAdjustments,
    );

    try {
      final record = await library.saveLocal(importedPreset);
      _upsertRecord(record);
      _errorMessage = null;
      _notifyListeners();
      return record;
    } on Object catch (error) {
      _rememberMutationError(error);
      rethrow;
    }
  }

  Future<PresetRecord> renameLocal(String libraryId, String newName) async {
    final library = _requireLibrary();

    try {
      final record = await library.renameLocal(libraryId, newName);
      _upsertRecord(record);
      _errorMessage = null;
      _notifyListeners();
      return record;
    } on Object catch (error) {
      _rememberMutationError(error);
      rethrow;
    }
  }

  Future<void> delete(String libraryId) async {
    final library = _requireLibrary();

    try {
      await library.delete(libraryId);
      _records = _records
          .where((record) => record.libraryId != libraryId)
          .toList(growable: false);
      _errorMessage = null;
      _notifyListeners();
    } on Object catch (error) {
      _rememberMutationError(error);
      rethrow;
    }
  }

  PresetLibrary _requireLibrary() {
    final library = _library;

    if (library == null) {
      throw const PresetLibraryException('Preset library is not ready yet.');
    }

    return library;
  }

  void _upsertRecord(PresetRecord record) {
    final records = <PresetRecord>[
      ..._records.where((item) => item.libraryId != record.libraryId),
      record,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    _records = List<PresetRecord>.unmodifiable(records);
  }

  void _rememberMutationError(Object error) {
    _errorMessage = 'Preset library operation failed: $error';
    _notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  static String _defaultPresetId() {
    final timestamp = DateTime.now()
        .toUtc()
        .microsecondsSinceEpoch
        .toRadixString(36);
    final random = Random().nextInt(0x7fffffff).toRadixString(36);

    return 'local-$timestamp-$random';
  }
}
