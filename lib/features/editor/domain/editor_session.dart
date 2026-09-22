import 'crop_state.dart';
import 'export_settings.dart';
import 'image_adjustments.dart';

class EditorSession {
  const EditorSession({
    this.sourceImagePath,
    this.adjustments = ImageAdjustments.initial,
    this.crop = CropState.initial,
    this.activePresetId,
    this.exportSettings = ExportSettings.initial,
    this.isDirty = false,
  });

  final String? sourceImagePath;

  final ImageAdjustments adjustments;
  final CropState crop;

  final String? activePresetId;

  final ExportSettings exportSettings;

  final bool isDirty;

  bool get hasImage => sourceImagePath != null;

  static const EditorSession initial = EditorSession();

  EditorSession copyWith({
    String? sourceImagePath,
    bool clearSourceImage = false,
    ImageAdjustments? adjustments,
    CropState? crop,
    String? activePresetId,
    bool clearActivePreset = false,
    ExportSettings? exportSettings,
    bool? isDirty,
  }) {
    return EditorSession(
      sourceImagePath: clearSourceImage
          ? null
          : sourceImagePath ?? this.sourceImagePath,
      adjustments: adjustments ?? this.adjustments,
      crop: crop ?? this.crop,
      activePresetId: clearActivePreset
          ? null
          : activePresetId ?? this.activePresetId,
      exportSettings: exportSettings ?? this.exportSettings,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
