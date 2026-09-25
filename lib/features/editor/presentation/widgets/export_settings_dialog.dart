import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../domain/export_settings.dart';

Future<ExportSettings?> showExportSettingsDialog(
  BuildContext context, {
  required ExportSettings initialSettings,
}) {
  return showDialog<ExportSettings>(
    context: context,
    builder: (context) {
      return ExportSettingsDialog(initialSettings: initialSettings);
    },
  );
}

class ExportSettingsDialog extends StatefulWidget {
  const ExportSettingsDialog({required this.initialSettings, super.key});

  final ExportSettings initialSettings;

  @override
  State<ExportSettingsDialog> createState() => _ExportSettingsDialogState();
}

class _ExportSettingsDialogState extends State<ExportSettingsDialog> {
  late ExportSettings _settings;
  late final TextEditingController _maxDimensionController;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings.sanitized();
    _maxDimensionController = TextEditingController(
      text: _settings.maxDimension.toString(),
    );
  }

  @override
  void dispose() {
    _maxDimensionController.dispose();
    super.dispose();
  }

  int? get _parsedMaxDimension {
    final parsed = int.tryParse(_maxDimensionController.text);

    if (parsed == null ||
        parsed < ExportSettings.minimumMaxDimension ||
        parsed > ExportSettings.maximumMaxDimension) {
      return null;
    }

    return parsed;
  }

  bool get _canSubmit =>
      _settings.resolutionMode == ExportResolutionMode.original ||
      _parsedMaxDimension != null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('export-settings-dialog'),
      title: const Text('Export image'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Format', style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ExportFormat>(
                  key: const ValueKey('export-format-control'),
                  showSelectedIcon: false,
                  segments: ExportFormat.values.map((format) {
                    return ButtonSegment<ExportFormat>(
                      value: format,
                      label: Text(format.label),
                    );
                  }).toList(),
                  selected: {_settings.format},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _settings = _settings.copyWith(format: selection.single);
                    });
                  },
                ),
              ),
              if (_settings.usesQuality) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Text('Quality', style: AppTypography.label),
                    const Spacer(),
                    Text(
                      '${_settings.quality}%',
                      key: const ValueKey('export-quality-value'),
                      style: AppTypography.label,
                    ),
                  ],
                ),
                Slider(
                  key: const ValueKey('export-quality-slider'),
                  value: _settings.quality.toDouble(),
                  min: ExportSettings.minimumQuality.toDouble(),
                  max: ExportSettings.maximumQuality.toDouble(),
                  divisions:
                      ExportSettings.maximumQuality -
                      ExportSettings.minimumQuality,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(quality: value.round());
                    });
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const Text('Resolution', style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ExportResolutionMode>(
                  key: const ValueKey('export-resolution-control'),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ExportResolutionMode.original,
                      label: Text('Original'),
                    ),
                    ButtonSegment(
                      value: ExportResolutionMode.maxDimension,
                      label: Text('Limit longest edge'),
                    ),
                  ],
                  selected: {_settings.resolutionMode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _settings = _settings.copyWith(
                        resolutionMode: selection.single,
                      );
                    });
                  },
                ),
              ),
              if (_settings.resolutionMode ==
                  ExportResolutionMode.maxDimension) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const ValueKey('export-max-dimension'),
                  controller: _maxDimensionController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Longest edge',
                    suffixText: 'px',
                    errorText: _parsedMaxDimension == null
                        ? 'Enter 1–32768 px'
                        : null,
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Export renders again from the original image at the selected resolution.',
                style: AppTypography.bodyMuted,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('export-confirm'),
          onPressed: _canSubmit
              ? () {
                  final maxDimension = _parsedMaxDimension;
                  final settings = _settings.copyWith(
                    maxDimension: maxDimension ?? _settings.maxDimension,
                  );

                  Navigator.of(context).pop(settings.sanitized());
                }
              : null,
          child: const Text('Export'),
        ),
      ],
    );
  }
}
