import 'export_settings.dart';

class ExportRenderPlan {
  const ExportRenderPlan({
    required this.format,
    required this.quality,
    required this.fullResolutionWidth,
    required this.fullResolutionHeight,
    required this.outputWidth,
    required this.outputHeight,
  });

  final ExportFormat format;
  final int quality;

  /// Pixel dimensions produced by the full-resolution editor composition
  /// before an optional longest-edge export limit is applied.
  final int fullResolutionWidth;
  final int fullResolutionHeight;

  final int outputWidth;
  final int outputHeight;

  bool get isDownscaled =>
      outputWidth < fullResolutionWidth || outputHeight < fullResolutionHeight;

  double get aspectRatio => outputWidth / outputHeight;

  String get fileExtension => format.fileExtension;
}
