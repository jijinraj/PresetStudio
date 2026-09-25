enum ExportFormat { jpeg, png, webp }

extension ExportFormatX on ExportFormat {
  String get label => switch (this) {
    ExportFormat.jpeg => 'JPEG',
    ExportFormat.png => 'PNG',
    ExportFormat.webp => 'WebP',
  };

  String get fileExtension => switch (this) {
    ExportFormat.jpeg => 'jpg',
    ExportFormat.png => 'png',
    ExportFormat.webp => 'webp',
  };

  String get mimeType => switch (this) {
    ExportFormat.jpeg => 'image/jpeg',
    ExportFormat.png => 'image/png',
    ExportFormat.webp => 'image/webp',
  };

  bool get supportsQuality => switch (this) {
    ExportFormat.jpeg || ExportFormat.webp => true,
    ExportFormat.png => false,
  };
}

enum ExportResolutionMode { original, maxDimension }

class ExportSettings {
  const ExportSettings({
    this.format = ExportFormat.jpeg,
    this.quality = 92,
    this.resolutionMode = ExportResolutionMode.original,
    this.maxDimension = 2048,
  });

  static const int minimumQuality = 1;
  static const int maximumQuality = 100;

  static const int minimumMaxDimension = 1;
  static const int maximumMaxDimension = 32768;

  final ExportFormat format;

  /// Compression quality used by lossy formats such as JPEG and WebP.
  ///
  /// PNG ignores this value, but the setting is retained when switching
  /// formats so the user's previous quality choice is restored.
  final int quality;

  /// Whether export should keep the editor's full planned pixel dimensions or
  /// downscale them so the longest edge does not exceed [maxDimension].
  final ExportResolutionMode resolutionMode;

  final int maxDimension;

  static const ExportSettings initial = ExportSettings();

  bool get usesQuality => format.supportsQuality;

  ExportSettings sanitized() {
    return ExportSettings(
      format: format,
      quality: quality.clamp(minimumQuality, maximumQuality).toInt(),
      resolutionMode: resolutionMode,
      maxDimension: maxDimension
          .clamp(minimumMaxDimension, maximumMaxDimension)
          .toInt(),
    );
  }

  ExportSettings copyWith({
    ExportFormat? format,
    int? quality,
    ExportResolutionMode? resolutionMode,
    int? maxDimension,
  }) {
    return ExportSettings(
      format: format ?? this.format,
      quality: quality ?? this.quality,
      resolutionMode: resolutionMode ?? this.resolutionMode,
      maxDimension: maxDimension ?? this.maxDimension,
    );
  }
}
