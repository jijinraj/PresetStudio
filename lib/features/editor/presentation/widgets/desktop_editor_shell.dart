import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_dimensions.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../../presets/application/preset_library_controller.dart';
import '../../../presets/application/preset_remote_controller.dart';
import '../../../presets/presentation/widgets/preset_bottom_tray.dart';
import '../../application/editor_controller.dart';
import '../../domain/adjustment_definition.dart';
import '../../domain/adjustment_type.dart';
import '../../domain/image_adjustments.dart';
import 'adjustment_control.dart';
import 'before_after_button.dart';
import 'crop_workspace.dart';
import 'editor_history_list.dart';
import 'editor_image_viewport.dart';
import 'editor_viewport_controller.dart';
import 'flip_control.dart';
import 'hsl_color_mixer_editor.dart';
import 'rotation_control.dart';
import 'tone_curve_editor.dart';

enum _DesktopHistoryMenuAction { enableAll, clearHistory }

class DesktopEditorShell extends StatefulWidget {
  const DesktopEditorShell({
    required this.controller,
    this.presetLibraryController,
    this.presetRemoteController,
    required this.onImportImage,
    required this.isImporting,
    this.onExportImage,
    this.isExporting = false,
    super.key,
  });

  final EditorController controller;
  final PresetLibraryController? presetLibraryController;
  final PresetRemoteController? presetRemoteController;
  final Future<void> Function() onImportImage;
  final bool isImporting;
  final Future<void> Function()? onExportImage;
  final bool isExporting;

  @override
  State<DesktopEditorShell> createState() => _DesktopEditorShellState();
}

class _DesktopEditorShellState extends State<DesktopEditorShell> {
  late final EditorViewportController _viewportController;

  bool _isSideBySide = false;
  bool _isCropping = false;
  bool _isPresetTrayExpanded = true;

  @override
  void initState() {
    super.initState();
    _viewportController = EditorViewportController();
  }

  @override
  void dispose() {
    _viewportController.dispose();
    super.dispose();
  }

  void _toggleSideBySide() {
    if (_isCropping) {
      return;
    }

    _viewportController.reset();

    setState(() {
      _isSideBySide = !_isSideBySide;
    });
  }

  void _openCropWorkspace() {
    if (_isCropping || !widget.controller.session.hasImage) {
      return;
    }

    _viewportController.reset();

    setState(() {
      _isSideBySide = false;
      _isCropping = true;
    });
  }

  void _closeCropWorkspace() {
    if (!mounted) {
      return;
    }

    _viewportController.reset();

    setState(() {
      _isCropping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      body: Column(
        children: [
          _DesktopTopBar(
            controller: controller,
            isSideBySide: _isSideBySide,
            isCropping: _isCropping,
            onToggleSideBySide: _toggleSideBySide,
            onExportImage: widget.onExportImage,
            isExporting: widget.isExporting,
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: AppDimensions.libraryPanelWidth,
                  child: IgnorePointer(
                    ignoring: _isCropping,
                    child: _LibraryPanel(controller: controller),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      return ColoredBox(
                        color: AppColors.canvas,
                        child: _isCropping && controller.session.hasImage
                            ? CropWorkspace(
                                controller: controller,
                                onCancel: _closeCropWorkspace,
                                onDone: _closeCropWorkspace,
                              )
                            : _isSideBySide && controller.session.hasImage
                            ? _DesktopComparisonViewport(
                                controller: controller,
                                viewportController: _viewportController,
                                onImportImage: widget.onImportImage,
                                isImporting: widget.isImporting,
                              )
                            : EditorImageViewport(
                                sourceImagePath:
                                    controller.session.sourceImagePath,
                                adjustments: controller.previewAdjustments,
                                toneCurves: controller.previewToneCurves,
                                hslColorMixer: controller.previewHslColorMixer,
                                transform: controller.session.transform,
                                crop: controller.session.crop,
                                onImportImage: widget.onImportImage,
                                isImporting: widget.isImporting,
                                viewportController: _viewportController,
                              ),
                      );
                    },
                  ),
                ),
                if (!_isCropping) ...[
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: AppDimensions.adjustmentsPanelWidth,
                    child: _AdjustmentsPanel(
                      controller: controller,
                      onOpenCrop: _openCropWorkspace,
                      isCropping: _isCropping,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!_isCropping && widget.presetLibraryController != null) ...[
            const Divider(height: 1),
            _DesktopPresetTray(
              expanded: _isPresetTrayExpanded,
              onToggle: () {
                setState(() {
                  _isPresetTrayExpanded = !_isPresetTrayExpanded;
                });
              },
              child: PresetBottomTray(
                libraryController: widget.presetLibraryController!,
                remoteController: widget.presetRemoteController,
                editorController: controller,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DesktopComparisonViewport extends StatelessWidget {
  const _DesktopComparisonViewport({
    required this.controller,
    required this.viewportController,
    required this.onImportImage,
    required this.isImporting,
  });

  final EditorController controller;
  final EditorViewportController viewportController;
  final Future<void> Function() onImportImage;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    final sourceImagePath = controller.session.sourceImagePath;
    final transform = controller.session.transform;
    final crop = controller.session.crop;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: EditorImageViewport(
            sourceImagePath: sourceImagePath,
            adjustments: ImageAdjustments.initial,
            transform: transform,
            crop: crop,
            onImportImage: onImportImage,
            isImporting: isImporting,
            viewportController: viewportController,
            showChangeImageAction: false,
            showZoomControls: false,
            viewportLabel: 'BEFORE',
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: EditorImageViewport(
            sourceImagePath: sourceImagePath,
            adjustments: controller.previewAdjustments,
            toneCurves: controller.previewToneCurves,
            hslColorMixer: controller.previewHslColorMixer,
            transform: transform,
            crop: crop,
            onImportImage: onImportImage,
            isImporting: isImporting,
            viewportController: viewportController,
            viewportLabel: 'AFTER',
          ),
        ),
      ],
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.controller,
    required this.isSideBySide,
    required this.isCropping,
    required this.onToggleSideBySide,
    required this.onExportImage,
    required this.isExporting,
  });

  final EditorController controller;
  final bool isSideBySide;
  final bool isCropping;
  final VoidCallback onToggleSideBySide;
  final Future<void> Function()? onExportImage;
  final bool isExporting;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final canToggleSideBySide =
            !isCropping && (isSideBySide || controller.canCompareBefore);
        final canExport =
            !isCropping &&
            !isExporting &&
            controller.session.hasImage &&
            onExportImage != null;

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
                enabled: !isCropping && controller.canCompareBefore,
                isShowingBefore: controller.isShowingBefore,
                onPreviewStart: controller.beginBeforePreview,
                onPreviewEnd: controller.endBeforePreview,
              ),
              IconButton(
                key: const ValueKey('desktop-side-by-side'),
                tooltip: isSideBySide
                    ? 'Exit side-by-side comparison'
                    : 'Compare before and after side by side',
                onPressed: canToggleSideBySide ? onToggleSideBySide : null,
                style: IconButton.styleFrom(
                  foregroundColor: isSideBySide
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  backgroundColor: isSideBySide ? AppColors.accentMuted : null,
                ),
                icon: const Icon(Icons.compare),
              ),
              const Spacer(),
              FilledButton.icon(
                key: const ValueKey('desktop-export'),
                onPressed: canExport
                    ? () {
                        unawaited(onExportImage!());
                      }
                    : null,
                icon: isExporting
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined, size: 18),
                label: Text(isExporting ? 'Exporting…' : 'Export'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LibraryPanel extends StatefulWidget {
  const _LibraryPanel({required this.controller});

  final EditorController controller;

  @override
  State<_LibraryPanel> createState() => _LibraryPanelState();
}

class _LibraryPanelState extends State<_LibraryPanel> {
  bool _historyExpanded = true;

  EditorController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final editCount = controller.history.isEmpty
              ? 0
              : controller.history.length - 1;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Library', style: AppTypography.title),
              const SizedBox(height: AppSpacing.lg),
              _DesktopHistoryHeader(
                isExpanded: _historyExpanded,
                editCount: editCount,
                disabledCount: controller.disabledHistoryCount,
                canClearHistory: editCount > 0,
                onToggleExpanded: () {
                  setState(() {
                    _historyExpanded = !_historyExpanded;
                  });
                },
                onMenuAction: _handleHistoryMenuAction,
              ),
              if (_historyExpanded) ...[
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: EditorHistoryList(
                    controller: controller,
                    allowEditToggles: true,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleHistoryMenuAction(
    _DesktopHistoryMenuAction action,
  ) async {
    switch (action) {
      case _DesktopHistoryMenuAction.enableAll:
        controller.enableAllHistoryEntries();

      case _DesktopHistoryMenuAction.clearHistory:
        final shouldClear = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Clear history?'),
              content: const Text(
                'The current image will stay exactly as it is, but all '
                'previous undo and redo steps will be removed.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const ValueKey('desktop-history-clear-confirm'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Clear history'),
                ),
              ],
            );
          },
        );

        if (shouldClear == true && mounted) {
          controller.clearHistoryKeepingCurrent();
        }
    }
  }
}

class _DesktopPresetTray extends StatelessWidget {
  const _DesktopPresetTray({
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  static const double _collapsedHeight = 42;
  static const double _expandedHeight = 248;

  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: const ValueKey('desktop-presets-tray'),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: expanded ? _expandedHeight : _collapsedHeight,
      color: AppColors.surface,
      child: ClipRect(
        child: Column(
          children: [
            Material(
              color: AppColors.surface,
              child: InkWell(
                key: const ValueKey('desktop-presets-tray-toggle'),
                onTap: onToggle,
                child: SizedBox(
                  height: _collapsedHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Text('Presets', style: AppTypography.title),
                        const Spacer(),
                        Text(
                          expanded ? 'Hide' : 'Show',
                          style: AppTypography.label,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (expanded)
              Expanded(
                child: Padding(
                  key: const ValueKey('desktop-presets-tray-body'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: child,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DesktopHistoryHeader extends StatelessWidget {
  const _DesktopHistoryHeader({
    required this.isExpanded,
    required this.editCount,
    required this.disabledCount,
    required this.canClearHistory,
    required this.onToggleExpanded,
    required this.onMenuAction,
  });

  final bool isExpanded;
  final int editCount;
  final int disabledCount;
  final bool canClearHistory;
  final VoidCallback onToggleExpanded;
  final ValueChanged<_DesktopHistoryMenuAction> onMenuAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            key: const ValueKey('desktop-history-toggle'),
            borderRadius: BorderRadius.circular(4),
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  const Expanded(
                    child: Text(
                      'History',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text('$editCount', style: AppTypography.bodyMuted),
                  if (disabledCount > 0) ...[
                    const SizedBox(width: AppSpacing.xxs),
                    const Icon(
                      Icons.visibility_off_outlined,
                      size: 12,
                      color: AppColors.textDisabled,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: 28,
          height: 28,
          child: PopupMenuButton<_DesktopHistoryMenuAction>(
            key: const ValueKey('desktop-history-menu'),
            tooltip: 'History options',
            iconSize: 16,
            padding: EdgeInsets.zero,
            splashRadius: 16,
            onSelected: onMenuAction,
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  key: const ValueKey('history-menu-enable-all'),
                  value: _DesktopHistoryMenuAction.enableAll,
                  enabled: disabledCount > 0,
                  child: const Text('Enable all edits'),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  key: const ValueKey('history-menu-clear'),
                  value: _DesktopHistoryMenuAction.clearHistory,
                  enabled: canClearHistory,
                  child: const Text('Clear history…'),
                ),
              ];
            },
          ),
        ),
      ],
    );
  }
}

class _AdjustmentsPanel extends StatefulWidget {
  const _AdjustmentsPanel({
    required this.controller,
    required this.onOpenCrop,
    required this.isCropping,
  });

  final EditorController controller;
  final VoidCallback onOpenCrop;
  final bool isCropping;

  @override
  State<_AdjustmentsPanel> createState() => _AdjustmentsPanelState();
}

class _AdjustmentsPanelState extends State<_AdjustmentsPanel> {
  static const Duration _panelWheelBurstDelay = Duration(milliseconds: 300);

  Timer? _panelWheelBurstTimer;
  bool _panelOwnsWheelBurst = false;

  @override
  void dispose() {
    _panelWheelBurstTimer?.cancel();
    super.dispose();
  }

  bool _handlePanelScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification is! ScrollUpdateNotification) {
      return false;
    }

    _panelWheelBurstTimer?.cancel();

    _panelOwnsWheelBurst = true;

    _panelWheelBurstTimer = Timer(_panelWheelBurstDelay, () {
      _panelOwnsWheelBurst = false;
    });

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

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

    final temperatureDefinition = AdjustmentDefinitions.of(
      AdjustmentType.temperature,
    );

    final tintDefinition = AdjustmentDefinitions.of(AdjustmentType.tint);

    final vibranceDefinition = AdjustmentDefinitions.of(
      AdjustmentType.vibrance,
    );

    final saturationDefinition = AdjustmentDefinitions.of(
      AdjustmentType.saturation,
    );

    final vignetteAmountDefinition = AdjustmentDefinitions.of(
      AdjustmentType.vignetteAmount,
    );

    final vignetteFeatherDefinition = AdjustmentDefinitions.of(
      AdjustmentType.vignetteFeather,
    );

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final session = controller.session;
          final hasImage = session.hasImage;

          return NotificationListener<ScrollNotification>(
            onNotification: _handlePanelScrollNotification,
            child: SingleChildScrollView(
              key: const ValueKey('desktop-adjustments-scroll'),
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
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const ValueKey('desktop-open-crop'),
                        onPressed: widget.isCropping ? null : widget.onOpenCrop,
                        icon: const Icon(Icons.crop),
                        label: const Text('Crop & Straighten'),
                      ),
                    ),
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
                      wheelInteractionGuard: () => !_panelOwnsWheelBurst,
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
                      wheelInteractionGuard: () => !_panelOwnsWheelBurst,
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
                      wheelInteractionGuard: () => !_panelOwnsWheelBurst,
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
                      wheelInteractionGuard: () => !_panelOwnsWheelBurst,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AdjustmentControl(
                      definition: whitesDefinition,
                      value: session.adjustments.whites,
                      onChanged: (value) {
                        controller.updateAdjustment(
                          AdjustmentType.whites,
                          value,
                        );
                      },
                      onInteractionStart: controller.beginEditTransaction,
                      onInteractionEnd: controller.endEditTransaction,
                      wheelInteractionGuard: () => !_panelOwnsWheelBurst,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AdjustmentControl(
                      definition: blacksDefinition,
                      value: session.adjustments.blacks,
                      onChanged: (value) {
                        controller.updateAdjustment(
                          AdjustmentType.blacks,
                          value,
                        );
                      },
                      onInteractionStart: controller.beginEditTransaction,
                      onInteractionEnd: controller.endEditTransaction,
                      wheelInteractionGuard: () => !_panelOwnsWheelBurst,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.lg),
                    const Text('Color', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.md),
                    AdjustmentControl(
                      definition: temperatureDefinition,
                      value: session.adjustments.temperature,
                      onChanged: (value) {
                        controller.updateAdjustment(
                          AdjustmentType.temperature,
                          value,
                        );
                      },
                      onInteractionStart: controller.beginEditTransaction,
                      onInteractionEnd: controller.endEditTransaction,
                      wheelInteractionGuard: () => !_panelOwnsWheelBurst,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AdjustmentControl(
                      definition: tintDefinition,
                      value: session.adjustments.tint,
                      onChanged: (value) {
                        controller.updateAdjustment(AdjustmentType.tint, value);
                      },
                      onInteractionStart: controller.beginEditTransaction,
                      onInteractionEnd: controller.endEditTransaction,
                      wheelInteractionGuard: () => !_panelOwnsWheelBurst,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AdjustmentControl(
                      definition: vibranceDefinition,
                      value: session.adjustments.vibrance,
                      onChanged: (value) {
                        controller.updateAdjustment(
                          AdjustmentType.vibrance,
                          value,
                        );
                      },
                      onInteractionStart: controller.beginEditTransaction,
                      onInteractionEnd: controller.endEditTransaction,
                      wheelInteractionGuard: () => !_panelOwnsWheelBurst,
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                      wheelInteractionGuard: () => !_panelOwnsWheelBurst,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.lg),
                    const Text('Color Mixer', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.md),
                    HslColorMixerEditor(
                      key: const ValueKey('desktop-hsl-color-mixer'),
                      colorMixer: session.hslColorMixer,
                      onChanged: controller.updateHslColorMixer,
                      onInteractionStart: controller.beginEditTransaction,
                      onInteractionEnd: controller.endEditTransaction,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.lg),
                    const Text('Curves', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.md),
                    ToneCurveEditor(
                      key: const ValueKey('desktop-tone-curve-editor'),
                      toneCurves: session.effectiveToneCurves,
                      onChanged: controller.updateToneCurves,
                      onInteractionStart: controller.beginEditTransaction,
                      onInteractionEnd: controller.endEditTransaction,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.lg),
                    const Text('Effects', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.md),
                    AdjustmentControl(
                      definition: vignetteAmountDefinition,
                      value: session.adjustments.vignetteAmount,
                      onChanged: (value) {
                        controller.updateAdjustment(
                          AdjustmentType.vignetteAmount,
                          value,
                        );
                      },
                      onInteractionStart: controller.beginEditTransaction,
                      onInteractionEnd: controller.endEditTransaction,
                      wheelInteractionGuard: () => !_panelOwnsWheelBurst,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AdjustmentControl(
                      definition: vignetteFeatherDefinition,
                      value: session.adjustments.vignetteFeather,
                      onChanged: (value) {
                        controller.updateAdjustment(
                          AdjustmentType.vignetteFeather,
                          value,
                        );
                      },
                      onInteractionStart: controller.beginEditTransaction,
                      onInteractionEnd: controller.endEditTransaction,
                      wheelInteractionGuard: () => !_panelOwnsWheelBurst,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
