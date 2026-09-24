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
import 'before_after_button.dart';
import 'editor_history_list.dart';
import 'editor_image_viewport.dart';
import 'flip_control.dart';
import 'rotation_control.dart';

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
          _DesktopTopBar(controller: controller),
          const Divider(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: AppDimensions.libraryPanelWidth,
                  child: _LibraryPanel(controller: controller),
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
                          adjustments: controller.previewAdjustments,
                          transform: controller.session.transform,
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
  const _DesktopTopBar({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          height: AppDimensions.toolbarHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          color: AppColors.surface,
          child: Row(
            children: [
              const Text(AppConstants.appName, style: AppTypography.title),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                key: const ValueKey('desktop-undo'),
                tooltip: 'Undo (Ctrl+Z)',
                onPressed: controller.canUndo ? controller.undo : null,
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                key: const ValueKey('desktop-redo'),
                tooltip: 'Redo (Ctrl+Shift+Z)',
                onPressed: controller.canRedo ? controller.redo : null,
                icon: const Icon(Icons.redo),
              ),
              BeforeAfterButton(
                key: const ValueKey('desktop-before-after'),
                enabled: controller.canCompareBefore,
                isShowingBefore: controller.isShowingBefore,
                onPreviewStart: controller.beginBeforePreview,
                onPreviewEnd: controller.endBeforePreview,
              ),
              const Spacer(),
              const FilledButton(onPressed: null, child: Text('Export')),
            ],
          ),
        );
      },
    );
  }
}

class _LibraryPanel extends StatelessWidget {
  const _LibraryPanel({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Library', style: AppTypography.title),
          const SizedBox(height: AppSpacing.lg),
          const Text('Presets', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Your preset library will appear here.',
            style: AppTypography.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.lg),
          const Text('History', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: EditorHistoryList(controller: controller)),
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

    final contrastDefinition = AdjustmentDefinitions.of(
      AdjustmentType.contrast,
    );

    final highlightsDefinition = AdjustmentDefinitions.of(
      AdjustmentType.highlights,
    );

    final shadowsDefinition = AdjustmentDefinitions.of(AdjustmentType.shadows);

    final whitesDefinition = AdjustmentDefinitions.of(AdjustmentType.whites);

    final blacksDefinition = AdjustmentDefinitions.of(AdjustmentType.blacks);

    final saturationDefinition = AdjustmentDefinitions.of(
      AdjustmentType.saturation,
    );

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final session = controller.session;
          final hasImage = session.hasImage;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Adjustments', style: AppTypography.title),
                    ),
                    TextButton(
                      key: const ValueKey('desktop-reset-adjustments'),
                      onPressed: controller.canResetAdjustments
                          ? controller.resetAdjustments
                          : null,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!hasImage)
                  const Text(
                    'Select an image to start editing.',
                    style: AppTypography.bodyMuted,
                  )
                else ...[
                  const Text('Transform', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.md),
                  RotationControl(
                    transform: session.transform,
                    onChanged: controller.updateTransform,
                    onInteractionStart: controller.beginEditTransaction,
                    onInteractionEnd: controller.endEditTransaction,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FlipControl(
                    transform: session.transform,
                    onChanged: controller.updateTransform,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('Light', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.md),
                  AdjustmentControl(
                    definition: exposureDefinition,
                    value: session.adjustments.exposure,
                    onChanged: (value) {
                      controller.updateAdjustment(
                        AdjustmentType.exposure,
                        value,
                      );
                    },
                    onInteractionStart: controller.beginEditTransaction,
                    onInteractionEnd: controller.endEditTransaction,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AdjustmentControl(
                    definition: contrastDefinition,
                    value: session.adjustments.contrast,
                    onChanged: (value) {
                      controller.updateAdjustment(
                        AdjustmentType.contrast,
                        value,
                      );
                    },
                    onInteractionStart: controller.beginEditTransaction,
                    onInteractionEnd: controller.endEditTransaction,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AdjustmentControl(
                    definition: highlightsDefinition,
                    value: session.adjustments.highlights,
                    onChanged: (value) {
                      controller.updateAdjustment(
                        AdjustmentType.highlights,
                        value,
                      );
                    },
                    onInteractionStart: controller.beginEditTransaction,
                    onInteractionEnd: controller.endEditTransaction,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AdjustmentControl(
                    definition: shadowsDefinition,
                    value: session.adjustments.shadows,
                    onChanged: (value) {
                      controller.updateAdjustment(
                        AdjustmentType.shadows,
                        value,
                      );
                    },
                    onInteractionStart: controller.beginEditTransaction,
                    onInteractionEnd: controller.endEditTransaction,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AdjustmentControl(
                    definition: whitesDefinition,
                    value: session.adjustments.whites,
                    onChanged: (value) {
                      controller.updateAdjustment(AdjustmentType.whites, value);
                    },
                    onInteractionStart: controller.beginEditTransaction,
                    onInteractionEnd: controller.endEditTransaction,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AdjustmentControl(
                    definition: blacksDefinition,
                    value: session.adjustments.blacks,
                    onChanged: (value) {
                      controller.updateAdjustment(AdjustmentType.blacks, value);
                    },
                    onInteractionStart: controller.beginEditTransaction,
                    onInteractionEnd: controller.endEditTransaction,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('Color', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.md),
                  AdjustmentControl(
                    definition: saturationDefinition,
                    value: session.adjustments.saturation,
                    onChanged: (value) {
                      controller.updateAdjustment(
                        AdjustmentType.saturation,
                        value,
                      );
                    },
                    onInteractionStart: controller.beginEditTransaction,
                    onInteractionEnd: controller.endEditTransaction,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
