import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_dimensions.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';

class DesktopEditorShell extends StatelessWidget {
  const DesktopEditorShell({super.key});

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
                const Expanded(child: _CanvasArea()),
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
  const _CanvasArea();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppSpacing.xl),
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
