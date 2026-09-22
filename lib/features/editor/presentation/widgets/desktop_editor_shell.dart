import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_dimensions.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../application/editor_controller.dart';

class DesktopEditorShell extends StatelessWidget {
  const DesktopEditorShell({
    required this.controller,
    required this.onImportImage,
    required this.isImporting,
    super.key,
  });

  final EditorController controller;
  final Future<void> Function() onImportImage;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _DesktopTopBar(),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                const SizedBox(
                  width: AppDimensions.libraryPanelWidth,
                  child: _LibraryPanel(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      return _CanvasArea(
                        sourceImagePath: controller.session.sourceImagePath,
                        onImportImage: onImportImage,
                        isImporting: isImporting,
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                const SizedBox(
                  width: AppDimensions.adjustmentsPanelWidth,
                  child: _AdjustmentsPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.surface,
      child: Row(
        children: [
          const Text(AppConstants.appName, style: AppTypography.title),
          const Spacer(),
          FilledButton(onPressed: null, child: const Text('Export')),
        ],
      ),
    );
  }
}

class _LibraryPanel extends StatelessWidget {
  const _LibraryPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Library', style: AppTypography.title),
          SizedBox(height: AppSpacing.lg),
          Text('Presets', style: AppTypography.label),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Your preset library will appear here.',
            style: AppTypography.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _CanvasArea extends StatelessWidget {
  const _CanvasArea({
    required this.sourceImagePath,
    required this.onImportImage,
    required this.isImporting,
  });

  final String? sourceImagePath;
  final Future<void> Function() onImportImage;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    final path = sourceImagePath;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: path == null
            ? _EmptyCanvas(
                onImportImage: onImportImage,
                isImporting: isImporting,
              )
            : _LoadedImageState(
                sourceImagePath: path,
                onImportImage: onImportImage,
                isImporting: isImporting,
              ),
      ),
    );
  }
}

class _EmptyCanvas extends StatelessWidget {
  const _EmptyCanvas({required this.onImportImage, required this.isImporting});

  final Future<void> Function() onImportImage;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.image_outlined,
          size: 40,
          color: AppColors.textDisabled,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text('Open an image', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Choose a JPEG, PNG, or WebP image from your device.',
          style: AppTypography.bodyMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: isImporting ? null : onImportImage,
          icon: const Icon(Icons.folder_open_outlined),
          label: Text(isImporting ? 'Opening...' : 'Choose image'),
        ),
      ],
    );
  }
}

class _LoadedImageState extends StatelessWidget {
  const _LoadedImageState({
    required this.sourceImagePath,
    required this.onImportImage,
    required this.isImporting,
  });

  final String sourceImagePath;
  final Future<void> Function() onImportImage;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    final fileName = sourceImagePath.split(RegExp(r'[\\/]')).last;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 40,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(fileName, style: AppTypography.title, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Image loaded and ready for editing.',
          style: AppTypography.bodyMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: isImporting ? null : onImportImage,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Change image'),
        ),
      ],
    );
  }
}

class _AdjustmentsPanel extends StatelessWidget {
  const _AdjustmentsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Adjustments', style: AppTypography.title),
          SizedBox(height: AppSpacing.lg),
          Text('Light', style: AppTypography.label),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Editing controls will appear here.',
            style: AppTypography.bodyMuted,
          ),
        ],
      ),
    );
  }
}
