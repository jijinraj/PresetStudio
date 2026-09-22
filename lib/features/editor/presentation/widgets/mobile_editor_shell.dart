import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_dimensions.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';

class MobileEditorShell extends StatelessWidget {
  const MobileEditorShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(onPressed: null, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: const _MobileCanvasArea(),
      bottomNavigationBar: const _MobileToolBar(),
    );
  }
}

class _MobileCanvasArea extends StatelessWidget {
  const _MobileCanvasArea();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 40, color: AppColors.textDisabled),
            SizedBox(height: AppSpacing.sm),
            Text('Canvas', style: AppTypography.title),
            SizedBox(height: AppSpacing.xs),
            Text('No image loaded', style: AppTypography.bodyMuted),
          ],
        ),
      ),
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
