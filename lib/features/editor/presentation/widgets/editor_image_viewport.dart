import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_radii.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../domain/image_adjustments.dart';
import 'editor_rendered_image.dart';

class EditorImageViewport extends StatelessWidget {
  const EditorImageViewport({
    required this.sourceImagePath,
    required this.adjustments,
    required this.onImportImage,
    required this.isImporting,
    super.key,
  });

  final String? sourceImagePath;
  final ImageAdjustments adjustments;

  final Future<void> Function() onImportImage;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    final path = sourceImagePath;

    if (path == null) {
      return _EmptyViewport(
        onImportImage: onImportImage,
        isImporting: isImporting,
      );
    }

    return _LoadedViewport(
      sourceImagePath: path,
      adjustments: adjustments,
      onImportImage: onImportImage,
      isImporting: isImporting,
    );
  }
}

class _EmptyViewport extends StatelessWidget {
  const _EmptyViewport({
    required this.onImportImage,
    required this.isImporting,
  });

  final Future<void> Function() onImportImage;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
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
        ),
      ),
    );
  }
}

class _LoadedViewport extends StatelessWidget {
  const _LoadedViewport({
    required this.sourceImagePath,
    required this.adjustments,
    required this.onImportImage,
    required this.isImporting,
  });

  final String sourceImagePath;
  final ImageAdjustments adjustments;

  final Future<void> Function() onImportImage;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: EditorRenderedImage(
              sourceImagePath: sourceImagePath,
              adjustments: adjustments,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) {
                return _ImageLoadError(
                  onImportImage: onImportImage,
                  isImporting: isImporting,
                );
              },
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.md,
          right: AppSpacing.md,
          child: _ChangeImageButton(
            onImportImage: onImportImage,
            isImporting: isImporting,
          ),
        ),
      ],
    );
  }
}

class _ChangeImageButton extends StatelessWidget {
  const _ChangeImageButton({
    required this.onImportImage,
    required this.isImporting,
  });

  final Future<void> Function() onImportImage;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: TextButton.icon(
        onPressed: isImporting ? null : onImportImage,
        icon: const Icon(Icons.swap_horiz, size: 18),
        label: Text(isImporting ? 'Opening...' : 'Change image'),
      ),
    );
  }
}

class _ImageLoadError extends StatelessWidget {
  const _ImageLoadError({
    required this.onImportImage,
    required this.isImporting,
  });

  final Future<void> Function() onImportImage;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('Unable to display image', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'The file may be missing, damaged, or unsupported.',
              style: AppTypography.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: isImporting ? null : onImportImage,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Choose another image'),
            ),
          ],
        ),
      ),
    );
  }
}
