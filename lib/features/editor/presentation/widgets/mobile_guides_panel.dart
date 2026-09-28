import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_dimensions.dart';
import '../../../../theme/tokens/app_radii.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import 'composition_guide_controller.dart';
import 'composition_guide_overlay.dart';

/// Mobile presentation for the existing composition-guide system.
///
/// All state remains in [CompositionGuideController], which is shared with the
/// crop workspace by the mobile editor shell. Guide changes are UI-only and do
/// not touch editor History, presets, adjustments, crop geometry, or export.
class MobileGuidesPanel extends StatelessWidget {
  const MobileGuidesPanel({required this.controller, super.key});

  final CompositionGuideController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final guide = controller.guide;

        return SingleChildScrollView(
          key: const ValueKey('mobile-guides-panel'),
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 72,
                child: SingleChildScrollView(
                  key: const ValueKey('mobile-guide-selector'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      for (
                        var index = 0;
                        index < CompositionGuideType.values.length;
                        index += 1
                      ) ...[
                        if (index > 0) const SizedBox(width: AppSpacing.xs),
                        _GuideSelectorItem(
                          key: ValueKey(
                            'mobile-guide-${CompositionGuideType.values[index].id}',
                          ),
                          guide: CompositionGuideType.values[index],
                          selected: CompositionGuideType.values[index] == guide,
                          onTap: () {
                            controller.selectGuide(
                              CompositionGuideType.values[index],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (guide != CompositionGuideType.none) ...[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Opacity',
                        style: AppTypography.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Slider(
                          key: const ValueKey('mobile-guide-opacity'),
                          value: controller.opacity,
                          min: 0.1,
                          max: 1,
                          divisions: 9,
                          onChanged: controller.setOpacity,
                        ),
                      ),
                      SizedBox(
                        width: 38,
                        child: Text(
                          '${(controller.opacity * 100).round()}%',
                          textAlign: TextAlign.end,
                          style: AppTypography.label,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Color',
                        style: AppTypography.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (
                                var index = 0;
                                index < CompositionGuideColor.values.length;
                                index += 1
                              ) ...[
                                if (index > 0)
                                  const SizedBox(width: AppSpacing.xs),
                                _GuideColorButton(
                                  key: ValueKey(
                                    'mobile-guide-color-${CompositionGuideColor.values[index].id}',
                                  ),
                                  color: CompositionGuideColor.values[index],
                                  selected:
                                      CompositionGuideColor.values[index] ==
                                      controller.color,
                                  onTap: () {
                                    controller.setColor(
                                      CompositionGuideColor.values[index],
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (guide.supportsOrientation) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Orientation',
                          style: AppTypography.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        _GuideActionButton(
                          key: const ValueKey('mobile-guide-rotate'),
                          icon: Icons.rotate_right,
                          tooltip: 'Rotate guide',
                          onTap: controller.rotateClockwise,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _GuideActionButton(
                          key: const ValueKey('mobile-guide-flip-horizontal'),
                          icon: Icons.flip,
                          tooltip: 'Flip guide horizontally',
                          onTap: controller.flipHorizontal,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _GuideActionButton(
                          key: const ValueKey('mobile-guide-flip-vertical'),
                          icon: Icons.flip,
                          quarterTurns: 1,
                          tooltip: 'Flip guide vertically',
                          onTap: controller.flipVertical,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GuideSelectorItem extends StatelessWidget {
  const _GuideSelectorItem({
    required this.guide,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final CompositionGuideType guide;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.accent : AppColors.textSecondary;

    return Material(
      color: selected ? AppColors.accentMuted : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          width: 76,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _iconFor(guide),
                size: AppDimensions.iconMd,
                color: foreground,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                _shortLabelFor(guide),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _shortLabelFor(CompositionGuideType guide) {
    return switch (guide) {
      CompositionGuideType.none => 'None',
      CompositionGuideType.ruleOfThirds => 'Thirds',
      CompositionGuideType.centerSymmetry => 'Center',
      CompositionGuideType.squareGrid => 'Grid',
      CompositionGuideType.fineGrid => 'Fine',
      CompositionGuideType.phiGrid => 'Phi',
      CompositionGuideType.diagonalMethod => 'Diagonal',
      CompositionGuideType.goldenSpiral => 'Spiral',
      CompositionGuideType.goldenTriangle => 'Triangle',
    };
  }

  static IconData _iconFor(CompositionGuideType guide) {
    return switch (guide) {
      CompositionGuideType.none => Icons.block,
      CompositionGuideType.ruleOfThirds => Icons.grid_3x3,
      CompositionGuideType.centerSymmetry => Icons.center_focus_strong,
      CompositionGuideType.squareGrid => Icons.grid_4x4,
      CompositionGuideType.fineGrid => Icons.apps,
      CompositionGuideType.phiGrid => Icons.grid_on,
      CompositionGuideType.diagonalMethod => Icons.show_chart,
      CompositionGuideType.goldenSpiral => Icons.gesture,
      CompositionGuideType.goldenTriangle => Icons.change_history,
    };
  }
}

class _GuideColorButton extends StatelessWidget {
  const _GuideColorButton({
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final CompositionGuideColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: color.label,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Container(
          width: 30,
          height: 30,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.borderStrong,
              width: selected ? 2 : 1,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideActionButton extends StatelessWidget {
  const _GuideActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.quarterTurns = 0,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size.square(40),
      ),
      icon: RotatedBox(
        quarterTurns: quarterTurns,
        child: Icon(icon, size: AppDimensions.iconMd),
      ),
    );
  }
}
