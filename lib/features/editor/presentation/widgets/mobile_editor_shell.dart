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
    return Container(
      height: AppDimensions.mobileBottomBarHeight,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
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
                onTap: () {
                  _showEditSheet(context);
                },
              ),
            ),
            const Expanded(
              child: _MobileTool(icon: Icons.crop, label: 'Crop'),
            ),
          ],
        ),
      ),
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
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.lg,
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
                      enabled: session.sourceImagePath != null,
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
}

class _MobileTool extends StatelessWidget {
  const _MobileTool({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: AppDimensions.iconMd,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: AppTypography.label),
        ],
      ),
    );
  }
}
