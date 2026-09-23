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
import 'rotation_control.dart';

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
            color: AppColors.canvas,
            child: EditorImageViewport(
              sourceImagePath: controller.session.sourceImagePath,
              adjustments: controller.session.adjustments,
              transform: controller.session.transform,
              onImportImage: onImportImage,
              isImporting: isImporting,
            ),
          );
        },
      ),
      bottomNavigationBar: _MobileToolBar(controller: controller),
    );
  }
}

class _MobileToolBar extends StatelessWidget {
  const _MobileToolBar({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final hasImage = controller.session.sourceImagePath != null;

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: AppDimensions.mobileBottomBarHeight,
              child: Row(
                children: [
                  const Expanded(
                    child: _MobileTool(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Looks',
                    ),
                  ),
                  Expanded(
                    child: _MobileTool(
                      icon: Icons.tune,
                      label: 'Edit',
                      enabled: hasImage,
                      onTap: hasImage
                          ? () {
                              _showEditSheet(context);
                            }
                          : null,
                    ),
                  ),
                  Expanded(
                    child: _MobileTool(
                      icon: Icons.crop,
                      label: 'Crop',
                      enabled: hasImage,
                      onTap: hasImage
                          ? () {
                              _showCropSheet(context);
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditSheet(BuildContext context) {
    final exposureDefinition = AdjustmentDefinitions.of(
      AdjustmentType.exposure,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.lg + bottomInset,
            ),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final session = controller.session;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edit', style: AppTypography.title),
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
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showCropSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.lg + bottomInset,
            ),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final session = controller.session;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Crop & Transform', style: AppTypography.title),
                    const SizedBox(height: AppSpacing.lg),
                    const Text('Rotation', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.md),
                    RotationControl(
                      transform: session.transform,
                      onChanged: controller.updateTransform,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _MobileTool extends StatelessWidget {
  const _MobileTool({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.textSecondary : AppColors.textDisabled;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppDimensions.iconMd, color: color),
            const SizedBox(height: AppSpacing.xxs),
            Text(label, style: AppTypography.label.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
