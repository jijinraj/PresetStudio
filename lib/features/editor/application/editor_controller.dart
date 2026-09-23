import 'package:flutter/foundation.dart';

import '../domain/adjustment_type.dart';
import '../domain/crop_state.dart';
import '../domain/editor_session.dart';
import '../domain/export_settings.dart';
import '../domain/image_adjustments.dart';

class EditorController extends ChangeNotifier {
  EditorController({this._session = EditorSession.initial});

  EditorSession _session;

  EditorSession get session => _session;

  void setSourceImage(String path) {
    _session = _session.copyWith(
      sourceImagePath: path,
      adjustments: ImageAdjustments.initial,
      crop: CropState.initial,
      clearActivePreset: true,
      isDirty: false,
    );

    notifyListeners();
  }

  void clearSourceImage() {
    _session = EditorSession.initial;

    notifyListeners();
  }

  void updateAdjustments(ImageAdjustments adjustments) {
    _session = _session.copyWith(
      adjustments: adjustments.sanitized(),
      clearActivePreset: true,
      isDirty: true,
    );

    notifyListeners();
  }

  void updateAdjustment(AdjustmentType type, double value) {
    final adjustments = _session.adjustments.withValue(type, value);

    _session = _session.copyWith(
      adjustments: adjustments,
      clearActivePreset: true,
      isDirty: true,
    );

    notifyListeners();
  }

  void updateCrop(CropState crop) {
    _session = _session.copyWith(crop: crop, isDirty: true);

    notifyListeners();
  }

  void applyPreset({
    required String presetId,
    required ImageAdjustments adjustments,
  }) {
    _session = _session.copyWith(
      activePresetId: presetId,
      adjustments: adjustments.sanitized(),
      isDirty: true,
    );

    notifyListeners();
  }

  void updateExportSettings(ExportSettings settings) {
    _session = _session.copyWith(exportSettings: settings);

    notifyListeners();
  }

  void resetAdjustments() {
    _session = _session.copyWith(
      adjustments: ImageAdjustments.initial,
      clearActivePreset: true,
      isDirty: true,
    );

    notifyListeners();
  }

  void markSaved() {
    _session = _session.copyWith(isDirty: false);

    notifyListeners();
  }
}
