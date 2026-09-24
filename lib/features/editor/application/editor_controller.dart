import 'package:flutter/foundation.dart';

import '../domain/adjustment_definition.dart';
import '../domain/adjustment_type.dart';
import '../domain/crop_state.dart';
import '../domain/editor_session.dart';
import '../domain/export_settings.dart';
import '../domain/image_adjustments.dart';
import '../domain/image_transform.dart';
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

  EditorSession get session => _session;

  List<EditorHistoryEntry> get history => List.unmodifiable(_history);

  int get historyIndex => _historyIndex;

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
          session: _session,
        ),
      );

    _historyIndex = 0;

    _clearTransaction();

    notifyListeners();
  }

  void clearSourceImage() {
    _session = EditorSession.initial;
    _savedSession = _session;

    _history.clear();
    _historyIndex = -1;

    _clearTransaction();

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
      _session.copyWith(crop: crop),
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

  void applyPreset({
    required String presetId,
    required ImageAdjustments adjustments,
  }) {
    _applyEdit(
      _session.copyWith(
        activePresetId: presetId,
        adjustments: adjustments.sanitized(),
      ),
      label: 'Preset $presetId',
      action: EditorHistoryAction.preset,
    );
  }

  void updateExportSettings(ExportSettings settings) {
    _session = _session.copyWith(exportSettings: settings);

    notifyListeners();
  }

  void resetAdjustments() {
    _applyEdit(
      _session.copyWith(
        adjustments: ImageAdjustments.initial,
        clearActivePreset: true,
      ),
      label: 'Reset Adjustments',
      action: EditorHistoryAction.reset,
    );
  }

  void beginEditTransaction() {
    if (_transactionStart != null) {
      return;
    }

    _transactionStart = _session;
    _transactionLabel = null;
    _transactionAction = null;

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
        EditorHistoryEntry(label: label, action: action, session: _session),
      );
    }

    notifyListeners();
  }

  void undo() {
    if (!canUndo) {
      return;
    }

    _historyIndex -= 1;

    _restoreHistoryEntry(_history[_historyIndex]);

    notifyListeners();
  }

  void redo() {
    if (!canRedo) {
      return;
    }

    _historyIndex += 1;

    _restoreHistoryEntry(_history[_historyIndex]);

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

    _restoreHistoryEntry(_history[_historyIndex]);

    notifyListeners();
  }

  void markSaved() {
    _session = _session.copyWith(isDirty: false);

    _savedSession = _session;

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

    _session = _withDerivedDirtyState(candidate);

    if (_transactionStart != null) {
      _transactionLabel = label;
      _transactionAction = action;

      notifyListeners();

      return;
    }

    _truncateFutureHistory();

    _appendHistory(
      EditorHistoryEntry(label: label, action: action, session: _session),
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

  void _restoreHistoryEntry(EditorHistoryEntry entry) {
    final snapshot = entry.session;

    final restored = _session.copyWith(
      adjustments: snapshot.adjustments,
      transform: snapshot.transform,
      crop: snapshot.crop,
      activePresetId: snapshot.activePresetId,
      clearActivePreset: snapshot.activePresetId == null,
    );

    _session = _withDerivedDirtyState(restored);
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
        a.crop.aspectRatio == b.crop.aspectRatio &&
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
        a.saturation == b.saturation;
  }

  bool _sameTransform(ImageTransform a, ImageTransform b) {
    return a.normalizedRotationDegrees == b.normalizedRotationDegrees &&
        a.flipHorizontal == b.flipHorizontal &&
        a.flipVertical == b.flipVertical;
  }
}
