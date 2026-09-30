import 'package:flutter/foundation.dart';

import '../domain/adjustment_definition.dart';
import '../domain/adjustment_type.dart';
import '../domain/crop_state.dart';
import '../domain/editor_session.dart';
import '../domain/export_settings.dart';
import '../domain/image_adjustments.dart';
import '../domain/image_transform.dart';
import '../domain/tone_curves.dart';
import 'editor_history_entry.dart';

class EditorController extends ChangeNotifier {
  EditorController({EditorSession session = EditorSession.initial})
    : _session = session,
      _savedSession = session {
    if (session.hasImage) {
      _history.add(
        EditorHistoryEntry(
          label: 'Original',
          action: EditorHistoryAction.original,
          beforeSession: session,
          session: session,
        ),
      );

      _historyIndex = 0;
    }
  }

  static const int _historyLimit = 100;

  EditorSession _session;
  EditorSession _savedSession;

  final List<EditorHistoryEntry> _history = [];

  int _historyIndex = -1;

  EditorSession? _transactionStart;
  String? _transactionLabel;
  EditorHistoryAction? _transactionAction;
  bool _transactionDescriptorLocked = false;

  bool _isShowingBefore = false;

  bool get isShowingBefore => _isShowingBefore;

  bool get canCompareBefore =>
      _session.hasImage &&
      (!_session.adjustments.isDefault ||
          !_session.effectiveToneCurves.isDefault);

  bool get canResetAdjustments =>
      _session.hasImage &&
      (!_session.adjustments.isDefault ||
          !_session.effectiveToneCurves.isDefault ||
          _session.activePresetId != null);

  ImageAdjustments get previewAdjustments =>
      _isShowingBefore ? ImageAdjustments.initial : _session.adjustments;

  ToneCurves get previewToneCurves =>
      _isShowingBefore ? ToneCurves.initial : _session.effectiveToneCurves;

  EditorSession get session => _session;

  List<EditorHistoryEntry> get history => List.unmodifiable(_history);

  int get historyIndex => _historyIndex;

  int get disabledHistoryCount =>
      _history.skip(1).where((entry) => !entry.isEnabled).length;

  EditorHistoryEntry? get currentHistoryEntry {
    if (_historyIndex < 0 || _historyIndex >= _history.length) {
      return null;
    }

    return _history[_historyIndex];
  }

  bool get isEditTransactionActive => _transactionStart != null;

  bool get canUndo => !isEditTransactionActive && _historyIndex > 0;

  bool get canRedo =>
      !isEditTransactionActive &&
      _historyIndex >= 0 &&
      _historyIndex < _history.length - 1;

  void setSourceImage(String path) {
    _session = _session.copyWith(
      sourceImagePath: path,
      adjustments: ImageAdjustments.initial,
      transform: ImageTransform.initial,
      crop: CropState.initial,
      clearToneCurves: true,
      clearActivePreset: true,
      isDirty: false,
    );

    _savedSession = _session;

    _history
      ..clear()
      ..add(
        EditorHistoryEntry(
          label: 'Original',
          action: EditorHistoryAction.original,
          beforeSession: _session,
          session: _session,
        ),
      );

    _historyIndex = 0;

    _clearTransaction();
    _isShowingBefore = false;

    notifyListeners();
  }

  void clearSourceImage() {
    _session = EditorSession.initial;
    _savedSession = _session;

    _history.clear();
    _historyIndex = -1;

    _clearTransaction();
    _isShowingBefore = false;

    notifyListeners();
  }

  void updateAdjustments(ImageAdjustments adjustments) {
    _applyEdit(
      _session.copyWith(
        adjustments: adjustments.sanitized(),
        clearActivePreset: true,
      ),
      label: 'Adjustments',
      action: EditorHistoryAction.adjustment,
    );
  }

  void updateAdjustment(AdjustmentType type, double value) {
    final adjustments = _session.adjustments.withValue(type, value);

    final sanitizedValue = adjustments.valueFor(type);

    _applyEdit(
      _session.copyWith(adjustments: adjustments, clearActivePreset: true),
      label: _adjustmentHistoryLabel(type, sanitizedValue),
      action: EditorHistoryAction.adjustment,
    );
  }

  void updateCrop(CropState crop) {
    _applyEdit(
      _session.copyWith(crop: crop.sanitized()),
      label: 'Crop',
      action: EditorHistoryAction.crop,
    );
  }

  void updateTransform(ImageTransform transform) {
    _applyEdit(
      _session.copyWith(transform: transform),
      label: _transformHistoryLabel(_session.transform, transform),
      action: EditorHistoryAction.transform,
    );
  }

  void updateToneCurves(ToneCurves toneCurves) {
    _applyEdit(
      _session.copyWith(toneCurves: toneCurves, clearActivePreset: true),
      label: 'Tone Curves',
      action: EditorHistoryAction.adjustment,
    );
  }

  void applyPreset({
    required String presetId,
    String? presetName,
    required ImageAdjustments adjustments,
    ToneCurves? toneCurves,
  }) {
    final normalizedName = presetName?.trim();
    final label = normalizedName == null || normalizedName.isEmpty
        ? 'Preset $presetId'
        : 'Preset: $normalizedName';

    _applyEdit(
      _session.copyWith(
        activePresetId: presetId,
        adjustments: adjustments.sanitized(),
        toneCurves: toneCurves ?? ToneCurves.initial,
      ),
      label: label,
      action: EditorHistoryAction.preset,
    );
  }

  void updateExportSettings(ExportSettings settings) {
    _session = _session.copyWith(exportSettings: settings.sanitized());

    notifyListeners();
  }

  void beginBeforePreview() {
    if (!canCompareBefore || _isShowingBefore) {
      return;
    }

    _isShowingBefore = true;

    notifyListeners();
  }

  void endBeforePreview() {
    if (!_isShowingBefore) {
      return;
    }

    _isShowingBefore = false;

    notifyListeners();
  }

  void resetAdjustments() {
    _isShowingBefore = false;
    _applyEdit(
      _session.copyWith(
        adjustments: ImageAdjustments.initial,
        clearToneCurves: true,
        clearActivePreset: true,
      ),
      label: 'Reset Adjustments',
      action: EditorHistoryAction.reset,
    );
  }

  void beginEditTransaction() {
    _beginEditTransaction();
  }

  /// Starts one logical History operation that may contain several internal
  /// editor-state updates.
  ///
  /// Child calls such as [updateCrop], [updateTransform], or
  /// [updateAdjustment] can still update the live preview, but they cannot
  /// replace this transaction's semantic History label/action.
  void beginSemanticEditTransaction({
    required String label,
    required EditorHistoryAction action,
  }) {
    _beginEditTransaction(label: label, action: action, lockDescriptor: true);
  }

  /// Updates the final label for an active semantic transaction.
  ///
  /// This is intended for interactions whose useful label is only known when
  /// the gesture finishes, for example `Straighten +1.4°`.
  void updateSemanticEditTransactionLabel(String label) {
    if (_transactionStart == null || !_transactionDescriptorLocked) {
      return;
    }

    _transactionLabel = label;
  }

  /// Cancels the active interaction and restores the exact state from before
  /// it began without creating a History entry.
  void cancelEditTransaction() {
    final start = _transactionStart;

    if (start == null) {
      return;
    }

    _session = start;

    _clearTransaction();

    notifyListeners();
  }

  void endEditTransaction() {
    final start = _transactionStart;

    if (start == null) {
      return;
    }

    final changed = !_sameEditableState(start, _session);

    final label = _transactionLabel ?? 'Edit';

    final action = _transactionAction ?? EditorHistoryAction.adjustment;

    _clearTransaction();

    if (changed) {
      _truncateFutureHistory();

      _appendHistory(
        EditorHistoryEntry(
          label: label,
          action: action,
          beforeSession: start,
          session: _session,
        ),
      );
    }

    notifyListeners();
  }

  void undo() {
    if (!canUndo) {
      return;
    }

    _historyIndex -= 1;

    _rebuildSessionThroughHistoryIndex();

    notifyListeners();
  }

  void redo() {
    if (!canRedo) {
      return;
    }

    _historyIndex += 1;

    _rebuildSessionThroughHistoryIndex();

    notifyListeners();
  }

  void jumpToHistory(int index) {
    if (isEditTransactionActive) {
      return;
    }

    if (index < 0 || index >= _history.length || index == _historyIndex) {
      return;
    }

    _historyIndex = index;

    _rebuildSessionThroughHistoryIndex();

    notifyListeners();
  }

  void setHistoryEntryEnabled(int index, bool enabled) {
    if (isEditTransactionActive || index <= 0 || index >= _history.length) {
      return;
    }

    final entry = _history[index];

    if (entry.action == EditorHistoryAction.original ||
        entry.action == EditorHistoryAction.checkpoint ||
        entry.isEnabled == enabled) {
      return;
    }

    _history[index] = entry.copyWith(isEnabled: enabled);

    if (index <= _historyIndex) {
      _rebuildSessionThroughHistoryIndex();
    }

    notifyListeners();
  }

  void enableAllHistoryEntries() {
    if (isEditTransactionActive || disabledHistoryCount == 0) {
      return;
    }

    var changed = false;

    for (var index = 1; index < _history.length; index += 1) {
      final entry = _history[index];

      if (entry.isEnabled) {
        continue;
      }

      _history[index] = entry.copyWith(isEnabled: true);
      changed = true;
    }

    if (!changed) {
      return;
    }

    _rebuildSessionThroughHistoryIndex();

    notifyListeners();
  }

  void clearHistoryKeepingCurrent() {
    if (isEditTransactionActive || !_session.hasImage) {
      return;
    }

    _history
      ..clear()
      ..add(
        EditorHistoryEntry(
          label: 'Current state',
          action: EditorHistoryAction.checkpoint,
          beforeSession: _session,
          session: _session,
        ),
      );

    _historyIndex = 0;

    notifyListeners();
  }

  void markSaved() {
    _session = _session.copyWith(isDirty: false);

    _savedSession = _session;

    notifyListeners();
  }

  void _beginEditTransaction({
    String? label,
    EditorHistoryAction? action,
    bool lockDescriptor = false,
  }) {
    if (_transactionStart != null) {
      return;
    }

    _transactionStart = _session;
    _transactionLabel = label;
    _transactionAction = action;
    _transactionDescriptorLocked = lockDescriptor;

    notifyListeners();
  }

  void _applyEdit(
    EditorSession candidate, {
    required String label,
    required EditorHistoryAction action,
  }) {
    if (_sameEditableState(_session, candidate)) {
      return;
    }

    final before = _session;

    _session = _withDerivedDirtyState(candidate);

    if (_transactionStart != null) {
      if (!_transactionDescriptorLocked) {
        _transactionLabel = label;
        _transactionAction = action;
      }

      notifyListeners();

      return;
    }

    _truncateFutureHistory();

    _appendHistory(
      EditorHistoryEntry(
        label: label,
        action: action,
        beforeSession: before,
        session: _session,
      ),
    );

    notifyListeners();
  }

  void _appendHistory(EditorHistoryEntry entry) {
    _history.add(entry);

    _historyIndex = _history.length - 1;

    while (_history.length > _historyLimit + 1) {
      if (_history.length <= 1) {
        break;
      }

      _history.removeAt(1);

      _historyIndex -= 1;
    }
  }

  void _truncateFutureHistory() {
    if (_historyIndex < 0) {
      return;
    }

    if (_historyIndex >= _history.length - 1) {
      return;
    }

    _history.removeRange(_historyIndex + 1, _history.length);
  }

  void _rebuildSessionThroughHistoryIndex() {
    if (_historyIndex < 0 || _history.isEmpty) {
      return;
    }

    final baseline = _history.first.session;

    var rebuilt = _session.copyWith(
      adjustments: baseline.adjustments,
      transform: baseline.transform,
      crop: baseline.crop,
      toneCurves: baseline.toneCurves,
      clearToneCurves: baseline.toneCurves == null,
      activePresetId: baseline.activePresetId,
      clearActivePreset: baseline.activePresetId == null,
    );

    for (var index = 1; index <= _historyIndex; index += 1) {
      final entry = _history[index];

      if (!entry.isEnabled) {
        continue;
      }

      rebuilt = _applyHistoryOperation(rebuilt, entry);
    }

    _session = _withDerivedDirtyState(rebuilt);
  }

  EditorSession _applyHistoryOperation(
    EditorSession current,
    EditorHistoryEntry entry,
  ) {
    final before = entry.beforeSession;
    final after = entry.session;

    var adjustments = current.adjustments;

    if (before.adjustments.exposure != after.adjustments.exposure) {
      adjustments = adjustments.copyWith(exposure: after.adjustments.exposure);
    }

    if (before.adjustments.contrast != after.adjustments.contrast) {
      adjustments = adjustments.copyWith(contrast: after.adjustments.contrast);
    }

    if (before.adjustments.highlights != after.adjustments.highlights) {
      adjustments = adjustments.copyWith(
        highlights: after.adjustments.highlights,
      );
    }

    if (before.adjustments.shadows != after.adjustments.shadows) {
      adjustments = adjustments.copyWith(shadows: after.adjustments.shadows);
    }

    if (before.adjustments.whites != after.adjustments.whites) {
      adjustments = adjustments.copyWith(whites: after.adjustments.whites);
    }

    if (before.adjustments.blacks != after.adjustments.blacks) {
      adjustments = adjustments.copyWith(blacks: after.adjustments.blacks);
    }

    if (before.adjustments.temperature != after.adjustments.temperature) {
      adjustments = adjustments.copyWith(
        temperature: after.adjustments.temperature,
      );
    }

    if (before.adjustments.tint != after.adjustments.tint) {
      adjustments = adjustments.copyWith(tint: after.adjustments.tint);
    }

    if (before.adjustments.vibrance != after.adjustments.vibrance) {
      adjustments = adjustments.copyWith(vibrance: after.adjustments.vibrance);
    }

    if (before.adjustments.saturation != after.adjustments.saturation) {
      adjustments = adjustments.copyWith(
        saturation: after.adjustments.saturation,
      );
    }

    if (before.adjustments.vignetteAmount != after.adjustments.vignetteAmount) {
      adjustments = adjustments.copyWith(
        vignetteAmount: after.adjustments.vignetteAmount,
      );
    }

    if (before.adjustments.vignetteFeather !=
        after.adjustments.vignetteFeather) {
      adjustments = adjustments.copyWith(
        vignetteFeather: after.adjustments.vignetteFeather,
      );
    }

    var transform = current.transform;

    final beforeRotation = before.transform.normalizedRotationDegrees;
    final afterRotation = after.transform.normalizedRotationDegrees;

    if (beforeRotation != afterRotation) {
      final delta = _normalizeRotationDelta(afterRotation - beforeRotation);
      transform = transform.rotateBy(delta);
    }

    if (before.transform.flipHorizontal != after.transform.flipHorizontal) {
      transform = transform.toggleFlipHorizontal();
    }

    if (before.transform.flipVertical != after.transform.flipVertical) {
      transform = transform.toggleFlipVertical();
    }

    var crop = current.crop;

    if (before.crop != after.crop) {
      crop = after.crop;
    }

    var toneCurves = current.toneCurves;
    var clearToneCurves = false;

    if (before.effectiveToneCurves != after.effectiveToneCurves) {
      toneCurves = after.toneCurves;
      clearToneCurves = after.toneCurves == null;
    }

    var activePresetId = current.activePresetId;
    var clearActivePreset = false;

    if (before.activePresetId != after.activePresetId) {
      if (after.activePresetId == null) {
        clearActivePreset = true;
        activePresetId = null;
      } else {
        activePresetId = after.activePresetId;
      }
    }

    return current.copyWith(
      adjustments: adjustments,
      transform: transform,
      crop: crop,
      toneCurves: toneCurves,
      clearToneCurves: clearToneCurves,
      activePresetId: activePresetId,
      clearActivePreset: clearActivePreset,
    );
  }

  EditorSession _withDerivedDirtyState(EditorSession candidate) {
    return candidate.copyWith(
      isDirty: !_sameEditableState(candidate, _savedSession),
    );
  }

  void _clearTransaction() {
    _transactionStart = null;
    _transactionLabel = null;
    _transactionAction = null;
    _transactionDescriptorLocked = false;
  }

  String _adjustmentHistoryLabel(AdjustmentType type, double value) {
    final definition = AdjustmentDefinitions.of(type);

    final decimalPlaces = _decimalPlaces(definition.precisionStep);

    final formatted = value.toStringAsFixed(decimalPlaces);

    final signed = value > 0 ? '+$formatted' : formatted;

    return '${definition.label} $signed';
  }

  String _transformHistoryLabel(ImageTransform previous, ImageTransform next) {
    final previousRotation = previous.normalizedRotationDegrees;

    final nextRotation = next.normalizedRotationDegrees;

    if (previousRotation != nextRotation) {
      final delta = _normalizeRotationDelta(nextRotation - previousRotation);

      if (delta == 90.0) {
        return 'Rotate Right 90°';
      }

      if (delta == -90.0) {
        return 'Rotate Left 90°';
      }

      final value = _formatRotation(nextRotation);

      return 'Rotation $value°';
    }

    if (previous.flipHorizontal != next.flipHorizontal &&
        previous.flipVertical == next.flipVertical) {
      return next.flipHorizontal ? 'Horizontal Flip On' : 'Horizontal Flip Off';
    }

    if (previous.flipVertical != next.flipVertical &&
        previous.flipHorizontal == next.flipHorizontal) {
      return next.flipVertical ? 'Vertical Flip On' : 'Vertical Flip Off';
    }

    return 'Transform';
  }

  String _formatRotation(double value) {
    final rounded = (value * 10).round() / 10;

    if (rounded == rounded.round()) {
      return rounded.round().toString();
    }

    return rounded.toStringAsFixed(1);
  }

  double _normalizeRotationDelta(double value) {
    var normalized = value.remainder(360.0);

    if (normalized > 180.0) {
      normalized -= 360.0;
    } else if (normalized < -180.0) {
      normalized += 360.0;
    }

    if (normalized == 0.0) {
      return 0.0;
    }

    return normalized;
  }

  int _decimalPlaces(double value) {
    if (value == value.roundToDouble()) {
      return 0;
    }

    final text = value.toString();

    if (!text.contains('.')) {
      return 0;
    }

    return text.split('.').last.length;
  }

  bool _sameEditableState(EditorSession a, EditorSession b) {
    return a.sourceImagePath == b.sourceImagePath &&
        _sameAdjustments(a.adjustments, b.adjustments) &&
        _sameTransform(a.transform, b.transform) &&
        a.crop == b.crop &&
        a.effectiveToneCurves == b.effectiveToneCurves &&
        a.activePresetId == b.activePresetId;
  }

  bool _sameAdjustments(ImageAdjustments a, ImageAdjustments b) {
    return a.exposure == b.exposure &&
        a.contrast == b.contrast &&
        a.highlights == b.highlights &&
        a.shadows == b.shadows &&
        a.whites == b.whites &&
        a.blacks == b.blacks &&
        a.temperature == b.temperature &&
        a.tint == b.tint &&
        a.vibrance == b.vibrance &&
        a.saturation == b.saturation &&
        a.vignetteAmount == b.vignetteAmount &&
        a.vignetteFeather == b.vignetteFeather;
  }

  bool _sameTransform(ImageTransform a, ImageTransform b) {
    return a.normalizedRotationDegrees == b.normalizedRotationDegrees &&
        a.flipHorizontal == b.flipHorizontal &&
        a.flipVertical == b.flipVertical;
  }
}
