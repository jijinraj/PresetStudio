import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_dimensions.dart';
import '../../../../theme/tokens/app_radii.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../application/editor_controller.dart';
import '../../domain/adjustment_definition.dart';
import '../../domain/adjustment_type.dart';
import 'editor_ruler_control.dart';

/// Mobile-native adjustment workspace.
///
/// The panel deliberately keeps all edit state in [EditorController]. It only
/// owns the currently selected adjustment so the user can move through the
/// existing adjustment set while one precision ruler remains on screen.
class MobileAdjustmentPanel extends StatefulWidget {
  const MobileAdjustmentPanel({
    required this.controller,
    this.onPrecisionInteractionChanged,
    super.key,
  });

  final EditorController controller;

  /// Notifies the editor shell while the precision ruler is actively dragged.
  /// The shell uses this to enter a distraction-free image + dial mode.
  final ValueChanged<bool>? onPrecisionInteractionChanged;

  @override
  State<MobileAdjustmentPanel> createState() => _MobileAdjustmentPanelState();
}

class _MobileAdjustmentPanelState extends State<MobileAdjustmentPanel> {
  AdjustmentType _selected = AdjustmentType.exposure;
  bool _isPrecisionInteracting = false;

  EditorController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final definition = AdjustmentDefinitions.of(_selected);
        final value = controller.session.adjustments.valueFor(_selected);

        return SingleChildScrollView(
          key: const ValueKey('mobile-adjustment-panel'),
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PrecisionChromeVisibility(
                hidden: _isPrecisionInteracting,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Light & Color',
                          style: AppTypography.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        key: const ValueKey('mobile-adjustment-reset-all'),
                        onPressed: controller.canResetAdjustments
                            ? _resetAllAdjustments
                            : null,
                        icon: const Icon(Icons.restart_alt_rounded, size: 17),
                        label: const Text('Reset all'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _PrecisionChromeVisibility(
                hidden: _isPrecisionInteracting,
                child: SizedBox(
                  height: 70,
                  child: SingleChildScrollView(
                    key: const ValueKey('mobile-adjustment-selector'),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        for (
                          var index = 0;
                          index < AdjustmentType.values.length;
                          index += 1
                        ) ...[
                          if (index > 0) const SizedBox(width: AppSpacing.xs),
                          _AdjustmentSelectorItem(
                            key: ValueKey(
                              'mobile-adjustment-${AdjustmentType.values[index].name}',
                            ),
                            icon: _iconFor(AdjustmentType.values[index]),
                            label: AdjustmentDefinitions.of(
                              AdjustmentType.values[index],
                            ).label,
                            selected: AdjustmentType.values[index] == _selected,
                            onTap: () => _select(AdjustmentType.values[index]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey('mobile-adjustment-ruler-${_selected.name}'),
                    child: EditorRulerControl(
                      value: value,
                      minValue: definition.minValue,
                      maxValue: definition.maxValue,
                      defaultValue: definition.defaultValue,
                      precisionStep: definition.precisionStep,
                      interactionStep: definition.interactionStep,
                      minorTickStep: _minorTickStepFor(_selected),
                      majorTickStep: _majorTickStepFor(_selected),
                      pixelsPerMinorTick: _pixelsPerMinorTickFor(_selected),
                      rulerHeight: 76,
                      enableHaptics: true,
                      onInteractionStart: _beginInteraction,
                      onInteractionEnd: _endInteraction,
                      onChanged: (nextValue) {
                        controller.updateAdjustment(_selected, nextValue);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              _PrecisionChromeVisibility(
                hidden: _isPrecisionInteracting,
                child: Text(
                  'Double-tap the ruler to reset ${definition.label.toLowerCase()}.',
                  textAlign: TextAlign.center,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _select(AdjustmentType type) {
    if (type == _selected) {
      return;
    }

    if (controller.isEditTransactionActive) {
      controller.endEditTransaction();
    }

    setState(() {
      _selected = type;
    });
  }

  void _beginInteraction() {
    if (!controller.isEditTransactionActive) {
      controller.beginEditTransaction();
    }

    if (!_isPrecisionInteracting) {
      setState(() {
        _isPrecisionInteracting = true;
      });
      widget.onPrecisionInteractionChanged?.call(true);
    }
  }

  void _endInteraction() {
    if (controller.isEditTransactionActive) {
      controller.endEditTransaction();
    }

    if (_isPrecisionInteracting) {
      setState(() {
        _isPrecisionInteracting = false;
      });
      widget.onPrecisionInteractionChanged?.call(false);
    }
  }

  void _resetAllAdjustments() {
    if (controller.isEditTransactionActive) {
      controller.endEditTransaction();
    }
    controller.resetAdjustments();
  }

  static double _minorTickStepFor(AdjustmentType type) {
    return type == AdjustmentType.exposure ? 0.1 : 5;
  }

  static double _majorTickStepFor(AdjustmentType type) {
    return type == AdjustmentType.exposure ? 1 : 25;
  }

  static double _pixelsPerMinorTickFor(AdjustmentType type) {
    return type == AdjustmentType.exposure ? 12 : 8;
  }

  static IconData _iconFor(AdjustmentType type) {
    return switch (type) {
      AdjustmentType.exposure => Icons.brightness_6_outlined,
      AdjustmentType.contrast => Icons.contrast,
      AdjustmentType.highlights => Icons.light_mode_outlined,
      AdjustmentType.shadows => Icons.dark_mode_outlined,
      AdjustmentType.whites => Icons.flare_outlined,
      AdjustmentType.blacks => Icons.brightness_2_outlined,
      AdjustmentType.temperature => Icons.device_thermostat_outlined,
      AdjustmentType.tint => Icons.water_drop_outlined,
      AdjustmentType.vibrance => Icons.graphic_eq_rounded,
      AdjustmentType.saturation => Icons.opacity_outlined,
    };
  }
}

class _PrecisionChromeVisibility extends StatelessWidget {
  const _PrecisionChromeVisibility({required this.hidden, required this.child});

  final bool hidden;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: hidden,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        opacity: hidden ? 0 : 1,
        child: child,
      ),
    );
  }
}

class _AdjustmentSelectorItem extends StatelessWidget {
  const _AdjustmentSelectorItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
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
          width: 72,
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
              Icon(icon, size: AppDimensions.iconMd, color: foreground),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
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
}
