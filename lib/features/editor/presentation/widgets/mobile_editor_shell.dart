import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_dimensions.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../application/editor_controller.dart';

class MobileEditorShell extends StatelessWidget {
  const MobileEditorShell({
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
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(onPressed: null, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return _MobileCanvasArea(
            sourceImagePath: controller.session.sourceImagePath,
            onImportImage: onImportImage,
            isImporting: isImporting,
          );
        },
      ),
      bottomNavigationBar: const _MobileToolBar(),
    );
  }
}

class _MobileCanvasArea extends StatelessWidget {
  const _MobileCanvasArea({
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: path == null
            ? _MobileEmptyCanvas(
                onImportImage: onImportImage,
                isImporting: isImporting,
              )
            : _MobileLoadedImageState(
                sourceImagePath: path,
                onImportImage: onImportImage,
                isImporting: isImporting,
              ),
      ),
    );
  }
}

class _MobileEmptyCanvas extends StatelessWidget {
  const _MobileEmptyCanvas({
    required this.onImportImage,
    required this.isImporting,
  });

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
          'Choose a photo from your device.',
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

class _MobileLoadedImageState extends StatelessWidget {
  const _MobileLoadedImageState({
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
        OutlinedButton(
          onPressed: isImporting ? null : onImportImage,
          child: const Text('Change image'),
        ),
      ],
    );
  }
}

class _MobileToolBar extends StatelessWidget {
  const _MobileToolBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.mobileBottomBarHeight,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: const SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _MobileTool(
                icon: Icons.auto_awesome_outlined,
                label: 'Looks',
              ),
            ),
            Expanded(
              child: _MobileTool(icon: Icons.tune, label: 'Edit'),
            ),
            Expanded(
              child: _MobileTool(icon: Icons.crop, label: 'Crop'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileTool extends StatelessWidget {
  const _MobileTool({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: AppDimensions.iconMd, color: AppColors.textSecondary),
        const SizedBox(height: AppSpacing.xxs),
        Text(label, style: AppTypography.label),
      ],
    );
  }
}
