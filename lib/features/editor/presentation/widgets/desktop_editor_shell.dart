import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_dimensions.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../application/editor_controller.dart';
import '../../domain/adjustment_definition.dart';
import '../../domain/adjustment_type.dart';
import 'adjustment_control.dart';
import 'editor_image_viewport.dart';

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
                      return ColoredBox(
                        color: AppColors.canvas,
                        child: EditorImageViewport(
                          sourceImagePath: controller.session.sourceImagePath,
                          adjustments: controller.session.adjustments,
                          onImportImage: onImportImage,
                          isImporting: isImporting,
                        ),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: AppDimensions.adjustmentsPanelWidth,
                  child: _AdjustmentsPanel(controller: controller),
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

class _AdjustmentsPanel extends StatelessWidget {
  const _AdjustmentsPanel({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final exposureDefinition = AdjustmentDefinitions.of(
      AdjustmentType.exposure,
    );

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final session = controller.session;
          final hasImage = session.sourceImagePath != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Adjustments', style: AppTypography.title),
              const SizedBox(height: AppSpacing.lg),

              if (!hasImage)
                const Text(
                  'Select an image to start editing.',
                  style: AppTypography.bodyMuted,
                )
              else ...[
                const Text('Light', style: AppTypography.label),
                const SizedBox(height: AppSpacing.md),
                AdjustmentControl(
                  definition: exposureDefinition,
                  value: session.adjustments.exposure,
                  onChanged: (value) {
                    controller.updateAdjustment(AdjustmentType.exposure, value);
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
