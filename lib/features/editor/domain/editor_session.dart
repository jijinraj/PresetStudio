import 'crop_state.dart';
import 'export_settings.dart';
import 'image_adjustments.dart';
import 'image_transform.dart';
import 'tone_curves.dart';

class EditorSession {
  const EditorSession({
    this.sourceImagePath,
    this.adjustments = ImageAdjustments.initial,
    this.transform = ImageTransform.initial,
    this.crop = CropState.initial,
    this.toneCurves,
    this.activePresetId,
    this.exportSettings = ExportSettings.initial,
    this.isDirty = false,
  });

  final String? sourceImagePath;

  final ImageAdjustments adjustments;
  final ImageTransform transform;
  final CropState crop;
  final ToneCurves? toneCurves;

  ToneCurves get effectiveToneCurves => toneCurves ?? ToneCurves.initial;

  final String? activePresetId;

  final ExportSettings exportSettings;

  final bool isDirty;

  bool get hasImage => sourceImagePath != null;

  static const EditorSession initial = EditorSession();

  EditorSession copyWith({
    String? sourceImagePath,
    bool clearSourceImage = false,
    ImageAdjustments? adjustments,
    ImageTransform? transform,
    CropState? crop,
    ToneCurves? toneCurves,
    bool clearToneCurves = false,
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
      transform: transform ?? this.transform,
      crop: crop ?? this.crop,
      toneCurves: clearToneCurves ? null : toneCurves ?? this.toneCurves,
      activePresetId: clearActivePreset
          ? null
          : activePresetId ?? this.activePresetId,
      exportSettings: exportSettings ?? this.exportSettings,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
