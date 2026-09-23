import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_dimensions.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../application/editor_controller.dart';
import 'editor_image_viewport.dart';

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
          return ColoredBox(
            color: AppColors.background,
            child: EditorImageViewport(
              sourceImagePath: controller.session.sourceImagePath,
              onImportImage: onImportImage,
              isImporting: isImporting,
            ),
          );
        },
      ),
      bottomNavigationBar: const _MobileToolBar(),
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
