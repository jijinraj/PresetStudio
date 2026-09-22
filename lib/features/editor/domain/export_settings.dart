enum ExportFormat { jpeg, png }

class ExportSettings {
  const ExportSettings({
    this.format = ExportFormat.jpeg,
    this.jpegQuality = 92,
  });

  final ExportFormat format;
  final int jpegQuality;

  static const ExportSettings initial = ExportSettings();

  ExportSettings copyWith({ExportFormat? format, int? jpegQuality}) {
    return ExportSettings(
      format: format ?? this.format,
      jpegQuality: jpegQuality ?? this.jpegQuality,
    );
  }
}
