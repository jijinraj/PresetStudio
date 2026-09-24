import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_radii.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../domain/image_adjustments.dart';
import '../../domain/image_transform.dart';
import 'editor_rendered_image.dart';
import 'editor_viewport_controller.dart';

class EditorImageViewport extends StatefulWidget {
  const EditorImageViewport({
    required this.sourceImagePath,
    required this.adjustments,
    required this.transform,
    required this.onImportImage,
    required this.isImporting,
    this.viewportController,
    this.compactZoomControls = false,
    this.invertDesktopVerticalPan = true,
    super.key,
  });

  final String? sourceImagePath;
  final ImageAdjustments adjustments;
  final ImageTransform transform;

  final Future<void> Function() onImportImage;
  final bool isImporting;

  /// Optional UI-only camera controller.
  ///
  /// Passing one allows multiple viewports to share the same zoom and pan
  /// state, which is useful for synchronized comparison views.
  final EditorViewportController? viewportController;

  /// Uses a smaller Fit / percentage control intended for mobile.
  final bool compactZoomControls;

  /// Reverses only the vertical axis of mouse-drag panning on desktop.
  ///
  /// This stays outside editor state so a future preference can disable it
  /// without affecting history, presets, dirty state, or exports.
  final bool invertDesktopVerticalPan;

  @override
  State<EditorImageViewport> createState() => _EditorImageViewportState();
}

class _EditorImageViewportState extends State<EditorImageViewport> {
  late EditorViewportController _viewportController;
  late bool _ownsViewportController;

  @override
  void initState() {
    super.initState();
    _attachViewportController(widget.viewportController);
  }

  @override
  void didUpdateWidget(covariant EditorImageViewport oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.viewportController != widget.viewportController) {
      _detachOwnedViewportController();
      _attachViewportController(widget.viewportController);
    }

    if (oldWidget.sourceImagePath != widget.sourceImagePath) {
      _viewportController.reset();
    }
  }

  @override
  void dispose() {
    _detachOwnedViewportController();
    super.dispose();
  }

  void _attachViewportController(EditorViewportController? controller) {
    _ownsViewportController = controller == null;
    _viewportController = controller ?? EditorViewportController();
  }

  void _detachOwnedViewportController() {
    if (_ownsViewportController) {
      _viewportController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.sourceImagePath;

    if (path == null) {
      return _EmptyViewport(
        onImportImage: widget.onImportImage,
        isImporting: widget.isImporting,
      );
    }

    return _LoadedViewport(
      sourceImagePath: path,
      adjustments: widget.adjustments,
      transform: widget.transform,
      onImportImage: widget.onImportImage,
      isImporting: widget.isImporting,
      viewportController: _viewportController,
      compactZoomControls: widget.compactZoomControls,
      invertDesktopVerticalPan: widget.invertDesktopVerticalPan,
    );
  }
}

class _EmptyViewport extends StatelessWidget {
  const _EmptyViewport({
    required this.onImportImage,
    required this.isImporting,
  });

  final Future<void> Function() onImportImage;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_outlined,
              size: 40,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('Open an image', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Choose a JPEG, PNG, or WebP image from your device.',
              style: AppTypography.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: isImporting ? null : onImportImage,
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(isImporting ? 'Opening...' : 'Choose image'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedViewport extends StatefulWidget {
  const _LoadedViewport({
    required this.sourceImagePath,
    required this.adjustments,
    required this.transform,
    required this.onImportImage,
    required this.isImporting,
    required this.viewportController,
    required this.compactZoomControls,
    required this.invertDesktopVerticalPan,
  });

  final String sourceImagePath;
  final ImageAdjustments adjustments;
  final ImageTransform transform;

  final Future<void> Function() onImportImage;
  final bool isImporting;

  final EditorViewportController viewportController;
  final bool compactZoomControls;
  final bool invertDesktopVerticalPan;

  @override
  State<_LoadedViewport> createState() => _LoadedViewportState();
}

class _LoadedViewportState extends State<_LoadedViewport> {
  Offset _doubleTapPosition = Offset.zero;
  int? _desktopPanPointer;

  bool get _usesCustomDesktopMousePan {
    if (!widget.invertDesktopVerticalPan) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux => true,
      _ => false,
    };
  }

  void _handleDesktopPointerDown(PointerDownEvent event) {
    if (!_usesCustomDesktopMousePan ||
        event.kind != PointerDeviceKind.mouse ||
        event.buttons & kPrimaryMouseButton == 0 ||
        widget.viewportController.isFitted) {
      return;
    }

    _desktopPanPointer = event.pointer;
  }

  void _handleDesktopPointerMove(PointerMoveEvent event, Size viewportSize) {
    if (_desktopPanPointer != event.pointer ||
        event.kind != PointerDeviceKind.mouse ||
        event.buttons & kPrimaryMouseButton == 0) {
      return;
    }

    final pointerDelta = event.delta;

    widget.viewportController.panBy(
      Offset(pointerDelta.dx, -pointerDelta.dy),
      viewportSize: viewportSize,
    );
  }

  void _handleDesktopPointerEnd(PointerEvent event) {
    if (_desktopPanPointer == event.pointer) {
      _desktopPanPointer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        final viewportCenter = Offset(
          viewportSize.width / 2,
          viewportSize.height / 2,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            Listener(
              key: const ValueKey('editor-viewport-pointer-surface'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: _handleDesktopPointerDown,
              onPointerMove: (event) {
                _handleDesktopPointerMove(event, viewportSize);
              },
              onPointerUp: _handleDesktopPointerEnd,
              onPointerCancel: _handleDesktopPointerEnd,
              child: GestureDetector(
                key: const ValueKey('editor-viewport-gesture-surface'),
                behavior: HitTestBehavior.opaque,
                onDoubleTapDown: (details) {
                  _doubleTapPosition = details.localPosition;
                },
                onDoubleTap: () {
                  widget.viewportController.toggleDoubleTapZoom(
                    focalPoint: _doubleTapPosition,
                    viewportSize: viewportSize,
                  );
                },
                child: InteractiveViewer(
                  key: const ValueKey('editor-viewport-interactive'),
                  transformationController:
                      widget.viewportController.transformationController,
                  minScale: EditorViewportController.minimumScale,
                  maxScale: EditorViewportController.maximumScale,
                  // When inverted desktop panning is enabled, mouse-drag pan
                  // is handled by the Listener above. Mobile/touch keeps
                  // Flutter's normal direct-manipulation behavior.
                  panEnabled: !_usesCustomDesktopMousePan,
                  scaleEnabled: true,
                  trackpadScrollCausesScale: true,
                  scaleFactor: 320,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: viewportSize.width,
                    height: viewportSize.height,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: EditorRenderedImage(
                          sourceImagePath: widget.sourceImagePath,
                          adjustments: widget.adjustments,
                          transform: widget.transform,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stackTrace) {
                            return _ImageLoadError(
                              onImportImage: widget.onImportImage,
                              isImporting: widget.isImporting,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: _ChangeImageButton(
                onImportImage: widget.onImportImage,
                isImporting: widget.isImporting,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.md,
              child: Center(
                child: AnimatedBuilder(
                  animation: widget.viewportController,
                  builder: (context, _) {
                    if (widget.compactZoomControls) {
                      return _CompactZoomControl(
                        controller: widget.viewportController,
                      );
                    }

                    return _DesktopZoomControls(
                      controller: widget.viewportController,
                      viewportCenter: viewportCenter,
                      viewportSize: viewportSize,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DesktopZoomControls extends StatelessWidget {
  const _DesktopZoomControls({
    required this.controller,
    required this.viewportCenter,
    required this.viewportSize,
  });

  final EditorViewportController controller;
  final Offset viewportCenter;
  final Size viewportSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('editor-viewport-zoom-controls'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: SizedBox(
        height: 36,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: const ValueKey('editor-viewport-zoom-out'),
              onPressed: controller.canZoomOut
                  ? () {
                      controller.zoomOut(
                        focalPoint: viewportCenter,
                        viewportSize: viewportSize,
                      );
                    }
                  : null,
              tooltip: 'Zoom out',
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 52,
              child: Text(
                '${controller.percentage}%',
                key: const ValueKey('editor-viewport-zoom-label'),
                textAlign: TextAlign.center,
                style: AppTypography.label,
              ),
            ),
            IconButton(
              key: const ValueKey('editor-viewport-zoom-in'),
              onPressed: controller.canZoomIn
                  ? () {
                      controller.zoomIn(
                        focalPoint: viewportCenter,
                        viewportSize: viewportSize,
                      );
                    }
                  : null,
              tooltip: 'Zoom in',
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              icon: const Icon(Icons.add),
            ),
            const SizedBox(height: 20, child: VerticalDivider(width: 1)),
            TextButton(
              key: const ValueKey('editor-viewport-fit'),
              onPressed: controller.isFitted ? null : controller.reset,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 36),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: const Text('Fit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactZoomControl extends StatelessWidget {
  const _CompactZoomControl({required this.controller});

  final EditorViewportController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('editor-viewport-zoom-controls-compact'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: TextButton.icon(
        key: const ValueKey('editor-viewport-fit'),
        onPressed: controller.isFitted ? null : controller.reset,
        style: TextButton.styleFrom(
          minimumSize: const Size(72, 34),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        icon: const Icon(Icons.fit_screen_outlined, size: 16),
        label: Text(
          controller.isFitted ? 'Fit' : '${controller.percentage}%',
          key: const ValueKey('editor-viewport-zoom-label'),
        ),
      ),
    );
  }
}

class _ChangeImageButton extends StatelessWidget {
  const _ChangeImageButton({
    required this.onImportImage,
    required this.isImporting,
  });

  final Future<void> Function() onImportImage;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: TextButton.icon(
        onPressed: isImporting ? null : onImportImage,
        icon: const Icon(Icons.swap_horiz, size: 18),
        label: Text(isImporting ? 'Opening...' : 'Change image'),
      ),
    );
  }
}

class _ImageLoadError extends StatelessWidget {
  const _ImageLoadError({
    required this.onImportImage,
    required this.isImporting,
  });

  final Future<void> Function() onImportImage;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('Unable to display image', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'The file may be missing, damaged, or unsupported.',
              style: AppTypography.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: isImporting ? null : onImportImage,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Choose another image'),
            ),
          ],
        ),
      ),
    );
  }
}
