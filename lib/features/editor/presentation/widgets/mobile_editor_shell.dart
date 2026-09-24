import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_dimensions.dart';
import '../../../../theme/tokens/app_radii.dart';
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

enum _MobileMenuAction { history }

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
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final hasImage = controller.session.hasImage;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const ValueKey('mobile-undo'),
                    tooltip: 'Undo',
                    onPressed: controller.canUndo ? controller.undo : null,
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    key: const ValueKey('mobile-redo'),
                    tooltip: 'Redo',
                    onPressed: controller.canRedo ? controller.redo : null,
                    icon: const Icon(Icons.redo),
                  ),
                  PopupMenuButton<_MobileMenuAction>(
                    enabled: hasImage,
                    onSelected: (action) {
                      switch (action) {
                        case _MobileMenuAction.history:
                          _showHistorySheet(context);
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: _MobileMenuAction.history,
                          child: Row(
                            children: [
                              Icon(Icons.history),
                              SizedBox(width: AppSpacing.sm),
                              Text('History'),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
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
      bottomNavigationBar: _MobileToolBar(controller: controller),
    );
  }

  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height * 0.55;

        return SafeArea(
          top: false,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('History', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(child: EditorHistoryList(controller: controller)),
                ],
              ),
            ),
          ),
        );
      },
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
        final hasImage = controller.session.hasImage;

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

    final contrastDefinition = AdjustmentDefinitions.of(
      AdjustmentType.contrast,
    );

    final saturationDefinition = AdjustmentDefinitions.of(
      AdjustmentType.saturation,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      showDragHandle: false,
      isScrollControlled: true,
      builder: (context) {
        AdjustmentType? activeAdjustment;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

            final availableHeight = MediaQuery.sizeOf(context).height;

            final isFocused = activeAdjustment != null;

            void focusAdjustment(AdjustmentType type) {
              if (activeAdjustment == type) {
                return;
              }

              if (!controller.isEditTransactionActive) {
                controller.beginEditTransaction();
              }

              setSheetState(() {
                activeAdjustment = type;
              });
            }

            void leaveFocusedMode() {
              if (activeAdjustment == null) {
                return;
              }

              if (controller.isEditTransactionActive) {
                controller.endEditTransaction();
              }

              setSheetState(() {
                activeAdjustment = null;
              });
            }

            return SizedBox(
              height: availableHeight * 0.68,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  IgnorePointer(
                    ignoring: isFocused,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      opacity: isFocused ? 0.0 : 1.0,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          key: const ValueKey('mobile-edit-sheet-surface'),
                          constraints: BoxConstraints(
                            maxHeight: availableHeight * 0.68,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppRadii.md),
                            ),
                          ),
                          child: SafeArea(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 36,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: AppColors.borderStrong,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Row(
                                        children: [
                                          const Expanded(
                                            child: Text(
                                              'Edit',
                                              style: AppTypography.title,
                                            ),
                                          ),
                                          TextButton(
                                            key: const ValueKey(
                                              'mobile-reset-adjustments',
                                            ),
                                            onPressed:
                                                controller.canResetAdjustments
                                                ? controller.resetAdjustments
                                                : null,
                                            child: const Text('Reset'),
                                          ),
                                          BeforeAfterButton(
                                            key: const ValueKey(
                                              'mobile-before-after',
                                            ),
                                            enabled:
                                                controller.canCompareBefore,
                                            isShowingBefore:
                                                controller.isShowingBefore,
                                            onPreviewStart:
                                                controller.beginBeforePreview,
                                            onPreviewEnd:
                                                controller.endBeforePreview,
                                            compact: true,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      const Text(
                                        'Light',
                                        style: AppTypography.label,
                                      ),
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
                                        onInteractionStart: () {
                                          focusAdjustment(
                                            AdjustmentType.exposure,
                                          );
                                        },
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
                                        onInteractionStart: () {
                                          focusAdjustment(
                                            AdjustmentType.contrast,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      const Divider(height: 1),
                                      const SizedBox(height: AppSpacing.lg),
                                      const Text(
                                        'Color',
                                        style: AppTypography.label,
                                      ),
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
                                        onInteractionStart: () {
                                          focusAdjustment(
                                            AdjustmentType.saturation,
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isFocused)
                    AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        final type = activeAdjustment!;

                        final definition = AdjustmentDefinitions.of(type);

                        final value = switch (type) {
                          AdjustmentType.exposure =>
                            controller.session.adjustments.exposure,
                          AdjustmentType.contrast =>
                            controller.session.adjustments.contrast,
                          AdjustmentType.saturation =>
                            controller.session.adjustments.saturation,
                          _ => definition.defaultValue,
                        };

                        return _MobileFocusedAdjustmentBar(
                          definition: definition,
                          value: value,
                          onChanged: (nextValue) {
                            controller.updateAdjustment(type, nextValue);
                          },
                          onClose: leaveFocusedMode,
                          canCompareBefore: controller.canCompareBefore,
                          isShowingBefore: controller.isShowingBefore,
                          onBeforeStart: controller.beginBeforePreview,
                          onBeforeEnd: controller.endBeforePreview,
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (controller.isEditTransactionActive) {
        controller.endEditTransaction();
      }
    });
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
                    RotationControl(
                      transform: session.transform,
                      onChanged: controller.updateTransform,
                      onInteractionStart: controller.beginEditTransaction,
                      onInteractionEnd: controller.endEditTransaction,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.lg),
                    FlipControl(
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
    ).whenComplete(() {
      if (controller.isEditTransactionActive) {
        controller.endEditTransaction();
      }
    });
  }
}

class _MobileFocusedAdjustmentBar extends StatelessWidget {
  const _MobileFocusedAdjustmentBar({
    required this.definition,
    required this.value,
    required this.onChanged,
    required this.onClose,
    required this.canCompareBefore,
    required this.isShowingBefore,
    required this.onBeforeStart,
    required this.onBeforeEnd,
  });

  final AdjustmentDefinition definition;
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onClose;
  final bool canCompareBefore;
  final bool isShowingBefore;
  final VoidCallback onBeforeStart;
  final VoidCallback onBeforeEnd;

  @override
  Widget build(BuildContext context) {
    final sanitizedValue = definition.sanitize(value);

    final divisions =
        ((definition.maxValue - definition.minValue) /
                definition.interactionStep)
            .round();

    return Container(
      key: const ValueKey('mobile-focused-adjustment-bar'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 32,
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: BeforeAfterButton(
                        key: const ValueKey('mobile-focused-before-after'),
                        enabled: canCompareBefore,
                        isShowingBefore: isShowingBefore,
                        onPreviewStart: onBeforeStart,
                        onPreviewEnd: onBeforeEnd,
                        compact: true,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        definition.label,
                        textAlign: TextAlign.center,
                        style: AppTypography.label,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: IconButton(
                        key: const ValueKey('mobile-focused-close'),
                        onPressed: onClose,
                        tooltip: 'Back to adjustments',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatValue(definition, sanitizedValue),
                key: const ValueKey('mobile-focused-value'),
                style: AppTypography.title,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      key: const ValueKey('mobile-focused-decrement'),
                      onPressed: sanitizedValue <= definition.minValue
                          ? null
                          : () {
                              onChanged(
                                definition.sanitize(
                                  sanitizedValue - definition.interactionStep,
                                ),
                              );
                            },
                      tooltip: 'Decrease ${definition.label}',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      key: const ValueKey('mobile-focused-slider'),
                      value: sanitizedValue,
                      min: definition.minValue,
                      max: definition.maxValue,
                      divisions: divisions,
                      onChanged: (nextValue) {
                        onChanged(definition.sanitize(nextValue));
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      key: const ValueKey('mobile-focused-increment'),
                      onPressed: sanitizedValue >= definition.maxValue
                          ? null
                          : () {
                              onChanged(
                                definition.sanitize(
                                  sanitizedValue + definition.interactionStep,
                                ),
                              );
                            },
                      tooltip: 'Increase ${definition.label}',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatValue(AdjustmentDefinition definition, double value) {
    final decimalPlaces = _decimalPlaces(definition.precisionStep);

    final formatted = value.toStringAsFixed(decimalPlaces);

    return value > 0 ? '+$formatted' : formatted;
  }

  static int _decimalPlaces(double value) {
    if (value == value.roundToDouble()) {
      return 0;
    }

    final text = value.toString();

    if (!text.contains('.')) {
      return 0;
    }

    return text.split('.').last.length;
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
