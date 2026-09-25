import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../application/editor_controller.dart';
import '../../application/editor_history_entry.dart';
import '../../domain/crop_resize_geometry.dart';
import '../../domain/crop_state.dart';
import '../../domain/image_adjustments.dart';
import '../../domain/image_transform.dart';
import 'composition_guide_overlay.dart';
import 'editor_rendered_image.dart';

class CropWorkspace extends StatefulWidget {
  const CropWorkspace({
    required this.controller,
    required this.onCancel,
    required this.onDone,
    this.compact = false,
    super.key,
  });

  final EditorController controller;
  final VoidCallback onCancel;
  final VoidCallback onDone;
  final bool compact;

  @override
  State<CropWorkspace> createState() => _CropWorkspaceState();
}

class _CropWorkspaceState extends State<CropWorkspace> {
  static const List<_CropRatioOption> _ratioOptions = [
    _CropRatioOption(id: 'original', label: 'Original'),
    _CropRatioOption(id: '1x1', label: '1:1', ratio: 1),
    _CropRatioOption(id: '4x5', label: '4:5', ratio: 4 / 5),
    _CropRatioOption(id: '3x4', label: '3:4', ratio: 3 / 4),
    _CropRatioOption(id: '2x3', label: '2:3', ratio: 2 / 3),
    _CropRatioOption(id: '3x2', label: '3:2', ratio: 3 / 2),
    _CropRatioOption(id: '16x9', label: '16:9', ratio: 16 / 9),
    _CropRatioOption(id: '9x16', label: '9:16', ratio: 9 / 16),
  ];

  late final CropState _initialCrop;
  late final ImageTransform _initialTransform;

  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  double? _originalAspectRatio;
  String _selectedRatioId = 'original';
  CompositionGuideType _selectedGuide = CompositionGuideType.ruleOfThirds;

  bool _ownsTransaction = false;
  bool _finalized = false;

  EditorController get controller => widget.controller;

  @override
  void initState() {
    super.initState();

    _initialCrop = controller.session.crop;
    _initialTransform = controller.session.transform;

    _selectedRatioId = _ratioIdForCrop(_initialCrop);

    _resolveOriginalAspectRatio();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _finalized) {
        return;
      }

      _ensureTransactionStarted();
    });
  }

  @override
  void dispose() {
    _detachImageStream();

    // Crop is finalized through Cancel, Done, or PopScope before the workspace
    // closes. Do not mutate the externally-owned EditorController from dispose:
    // test/application teardown may dispose the controller before this widget.
    super.dispose();
  }

  void _ensureTransactionStarted() {
    if (_ownsTransaction || controller.isEditTransactionActive) {
      return;
    }

    controller.beginSemanticEditTransaction(
      label: 'Crop',
      action: EditorHistoryAction.crop,
    );

    _ownsTransaction = true;
  }

  void _resolveOriginalAspectRatio() {
    final path = controller.session.sourceImagePath;

    if (path == null) {
      return;
    }

    final provider = FileImage(File(path));

    final stream = provider.resolve(const ImageConfiguration());

    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (imageInfo, synchronousCall) {
        final width = imageInfo.image.width;
        final height = imageInfo.image.height;

        if (!mounted || width <= 0 || height <= 0) {
          return;
        }

        final ratio = width / height;

        setState(() {
          _originalAspectRatio = ratio;

          if (_initialCrop.aspectRatio == null ||
              _isClose(_initialCrop.aspectRatio!, ratio)) {
            _selectedRatioId = 'original';
          }
        });
      },
      onError: (error, stackTrace) {
        // The rendered-image widget already owns the user-facing load error.
        // Crop layout simply falls back to a neutral preview ratio here.
      },
    );

    _imageStream = stream;
    _imageStreamListener = listener;

    stream.addListener(listener);
  }

  void _detachImageStream() {
    final stream = _imageStream;
    final listener = _imageStreamListener;

    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }

    _imageStream = null;
    _imageStreamListener = null;
  }

  void _cancel() {
    if (_finalized) {
      return;
    }

    _finalized = true;

    if (_ownsTransaction && controller.isEditTransactionActive) {
      controller.cancelEditTransaction();
    }

    widget.onCancel();
  }

  void _done() {
    if (_finalized) {
      return;
    }

    _ensureTransactionStarted();

    controller.updateSemanticEditTransactionLabel(_historyLabel());

    _finalized = true;

    if (_ownsTransaction && controller.isEditTransactionActive) {
      controller.endEditTransaction();
    }

    widget.onDone();
  }

  String _historyLabel() {
    final crop = controller.session.crop;
    final transform = controller.session.transform;

    final cropBoundsChanged =
        crop.normalizedRect != _initialCrop.normalizedRect ||
        crop.aspectRatio != _initialCrop.aspectRatio;

    if (cropBoundsChanged) {
      return 'Crop · ${_selectedRatioLabel()}';
    }

    if (crop.straightenDegrees != _initialCrop.straightenDegrees) {
      return 'Straighten ${_formatSignedDegrees(crop.straightenDegrees)}';
    }

    if (_transformChanged(_initialTransform, transform)) {
      return 'Transform';
    }

    if (crop != _initialCrop) {
      return 'Crop';
    }

    return 'Crop';
  }

  void _selectRatio(_CropRatioOption option) {
    _ensureTransactionStarted();

    final current = controller.session.crop;

    CropState next;

    if (option.id == 'original') {
      final originalRatio = _originalAspectRatio;

      if (originalRatio == null) {
        return;
      }

      next = current.copyWith(
        normalizedRect: NormalizedCropRect.fullFrame,
        aspectRatio: originalRatio,
      );
    } else {
      final ratio = option.ratio!;

      next = current.copyWith(
        normalizedRect: _centeredRectForRatio(ratio),
        aspectRatio: ratio,
      );
    }

    setState(() {
      _selectedRatioId = option.id;
    });

    controller.updateCrop(next);
  }

  void _swapRatioOrientation() {
    _ensureTransactionStarted();

    final current = controller.session.crop;
    final currentRatio = current.aspectRatio;

    if (currentRatio == null ||
        !currentRatio.isFinite ||
        currentRatio <= 0 ||
        _isClose(currentRatio, 1)) {
      return;
    }

    final swappedRatio = 1 / currentRatio;

    final next = current.copyWith(
      normalizedRect: _centeredRectForRatio(swappedRatio),
      aspectRatio: swappedRatio,
    );

    setState(() {
      _selectedRatioId = _ratioIdForCrop(next);
    });

    controller.updateCrop(next);
  }

  NormalizedCropRect _centeredRectForRatio(double targetRatio) {
    final sourceRatio = _originalAspectRatio ?? 4 / 3;

    if (targetRatio <= sourceRatio) {
      final width = (targetRatio / sourceRatio).clamp(0.0, 1.0).toDouble();
      final inset = (1 - width) / 2;

      return NormalizedCropRect(
        left: inset,
        top: 0,
        right: 1 - inset,
        bottom: 1,
      );
    }

    final height = (sourceRatio / targetRatio).clamp(0.0, 1.0).toDouble();
    final inset = (1 - height) / 2;

    return NormalizedCropRect(left: 0, top: inset, right: 1, bottom: 1 - inset);
  }

  String _ratioIdForCrop(CropState crop) {
    final ratio = crop.aspectRatio;

    if (ratio == null) {
      return 'original';
    }

    // Prefer an exact listed orientation first.
    for (final option in _ratioOptions) {
      if (option.ratio != null && _isClose(option.ratio!, ratio)) {
        return option.id;
      }
    }

    // Ratios such as 5:4 and 4:3 are intentionally produced by the orientation
    // swap button without adding more chips to the strip. Keep the source chip
    // selected when its reciprocal is active.
    for (final option in _ratioOptions) {
      final optionRatio = option.ratio;

      if (optionRatio != null && _isClose(1 / optionRatio, ratio)) {
        return option.id;
      }
    }

    return 'original';
  }

  String _selectedRatioLabel() {
    final cropRatio = controller.session.crop.aspectRatio;

    if (cropRatio == null) {
      return 'Original';
    }

    for (final option in _ratioOptions) {
      final optionRatio = option.ratio;

      if (optionRatio == null) {
        continue;
      }

      if (_isClose(optionRatio, cropRatio)) {
        return option.label;
      }
    }

    for (final option in _ratioOptions) {
      final optionRatio = option.ratio;

      if (optionRatio == null) {
        continue;
      }

      if (_isClose(1 / optionRatio, cropRatio)) {
        return _reverseRatioLabel(option.label);
      }
    }

    if (_selectedRatioId == 'original') {
      return 'Original rotated';
    }

    return 'Crop';
  }

  static String _reverseRatioLabel(String label) {
    final parts = label.split(':');

    if (parts.length != 2) {
      return label;
    }

    return '${parts[1]}:${parts[0]}';
  }

  void _selectCompositionGuide(CompositionGuideType guide) {
    if (_selectedGuide == guide) {
      return;
    }

    setState(() {
      _selectedGuide = guide;
    });
  }

  void _updateStraighten(double degrees) {
    _ensureTransactionStarted();

    controller.updateCrop(
      controller.session.crop.copyWith(straightenDegrees: degrees),
    );
  }

  void _rotateLeft() {
    _ensureTransactionStarted();

    controller.updateTransform(
      controller.session.transform.rotateCounterClockwise(),
    );
  }

  void _rotateRight() {
    _ensureTransactionStarted();

    controller.updateTransform(controller.session.transform.rotateClockwise());
  }

  void _flipHorizontal() {
    _ensureTransactionStarted();

    controller.updateTransform(
      controller.session.transform.toggleFlipHorizontal(),
    );
  }

  void _flipVertical() {
    _ensureTransactionStarted();

    controller.updateTransform(
      controller.session.transform.toggleFlipVertical(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _cancel();
        }
      },
      child: Material(
        color: AppColors.canvas,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final session = controller.session;
            final sourceImagePath = session.sourceImagePath;

            if (sourceImagePath == null) {
              return const Center(
                child: Text(
                  'Open an image before cropping.',
                  style: AppTypography.bodyMuted,
                ),
              );
            }

            final crop = session.crop;

            return Column(
              children: [
                _CropWorkspaceTopBar(
                  compact: widget.compact,
                  onCancel: _cancel,
                  onDone: _done,
                ),
                const Divider(height: 1),
                Expanded(
                  child: _CropCanvas(
                    sourceImagePath: sourceImagePath,
                    adjustments: controller.previewAdjustments,
                    transform: session.transform,
                    crop: crop,
                    sourceAspectRatio: _originalAspectRatio ?? 4 / 3,
                    compositionGuide: _selectedGuide,
                    onCropChanged: (nextCrop) {
                      _ensureTransactionStarted();
                      controller.updateCrop(nextCrop);
                    },
                  ),
                ),
                const Divider(height: 1),
                _CropWorkspaceControls(
                  compact: widget.compact,
                  crop: crop,
                  transform: session.transform,
                  originalAspectRatio: _originalAspectRatio,
                  selectedRatioId: _selectedRatioId,
                  ratioOptions: _ratioOptions,
                  selectedGuide: _selectedGuide,
                  onSelectRatio: _selectRatio,
                  onSelectGuide: _selectCompositionGuide,
                  onSwapRatioOrientation: _swapRatioOrientation,
                  onStraightenChanged: _updateStraighten,
                  onRotateLeft: _rotateLeft,
                  onRotateRight: _rotateRight,
                  onFlipHorizontal: _flipHorizontal,
                  onFlipVertical: _flipVertical,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static bool _transformChanged(ImageTransform before, ImageTransform after) {
    return before.normalizedRotationDegrees !=
            after.normalizedRotationDegrees ||
        before.flipHorizontal != after.flipHorizontal ||
        before.flipVertical != after.flipVertical;
  }

  static bool _isClose(double a, double b) => (a - b).abs() < 0.000001;

  static String _formatSignedDegrees(double value) {
    final rounded = (value * 10).round() / 10;
    final text = rounded == rounded.round()
        ? rounded.round().toString()
        : rounded.toStringAsFixed(1);

    if (rounded > 0) {
      return '+$text°';
    }

    return '$text°';
  }
}

class _CropWorkspaceTopBar extends StatelessWidget {
  const _CropWorkspaceTopBar({
    required this.compact,
    required this.onCancel,
    required this.onDone,
  });

  final bool compact;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: compact ? 52 : 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              TextButton(
                key: const ValueKey('crop-cancel'),
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
              const Expanded(
                child: Text(
                  'Crop & Straighten',
                  textAlign: TextAlign.center,
                  style: AppTypography.title,
                ),
              ),
              FilledButton(
                key: const ValueKey('crop-done'),
                onPressed: onDone,
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropCanvas extends StatefulWidget {
  const _CropCanvas({
    required this.sourceImagePath,
    required this.adjustments,
    required this.transform,
    required this.crop,
    required this.sourceAspectRatio,
    required this.compositionGuide,
    required this.onCropChanged,
  });

  final String sourceImagePath;
  final ImageAdjustments adjustments;
  final ImageTransform transform;
  final CropState crop;
  final double sourceAspectRatio;
  final CompositionGuideType compositionGuide;
  final ValueChanged<CropState> onCropChanged;

  @override
  State<_CropCanvas> createState() => _CropCanvasState();
}

class _CropCanvasState extends State<_CropCanvas> {
  static const double _desktopMousePanHorizontalMultiplier = 1.75;
  static const double _desktopMousePanVerticalMultiplier = 3.0;

  CropState? _gestureStartCrop;
  Offset? _gestureStartFocalPoint;
  Size _frameSize = Size.zero;

  CropState? _resizeStartCrop;
  Offset? _resizeStartGlobalPosition;
  Size _resizeStageSize = Size.zero;
  CropResizeHandle? _activeResizeHandle;

  bool _isManipulatingImage = false;
  bool _isResizingCrop = false;
  PointerDeviceKind? _activePointerKind;
  Timer? _wheelIdleTimer;

  int? _activeMousePointer;
  bool _mouseMovedDuringGesture = false;

  DateTime? _lastClickTime;
  Offset? _lastClickPosition;

  bool get _usesInvertedDesktopMousePan {
    final isDesktopPlatform = switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux => true,
      _ => false,
    };

    return isDesktopPlatform && _activePointerKind == PointerDeviceKind.mouse;
  }

  @override
  void dispose() {
    _wheelIdleTimer?.cancel();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointerKind = event.kind;

    if (_isDesktopMouseEvent(event.kind) &&
        event.buttons == kPrimaryMouseButton) {
      _activeMousePointer = event.pointer;
      _mouseMovedDuringGesture = false;

      setState(() {
        _isManipulatingImage = true;
      });
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activeMousePointer != event.pointer || _frameSize.isEmpty) {
      return;
    }

    if (event.delta.distanceSquared > 0) {
      _mouseMovedDuringGesture = true;
    }

    final current = widget.crop;

    final currentTranslation = _translationFor(current, _frameSize);

    // PresetStudio desktop convention:
    // horizontal follows the mouse, vertical is inverted.
    final proposedTranslation =
        currentTranslation +
        Offset(
          event.delta.dx * _desktopMousePanHorizontalMultiplier,
          -event.delta.dy * _desktopMousePanVerticalMultiplier,
        );

    final geometry = _geometryFor(crop: current, frameSize: _frameSize);

    final clampedTranslation = geometry.clampTranslation(
      proposedTranslation,
      cropScale: current.scale,
    );

    widget.onCropChanged(
      current.copyWith(
        offset: _normalizedOffsetFor(clampedTranslation, _frameSize),
      ),
    );
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_activeMousePointer == event.pointer) {
      _activeMousePointer = null;

      if (!_mouseMovedDuringGesture) {
        _handleClickForReset(event.localPosition);
      }

      _mouseMovedDuringGesture = false;

      if (mounted) {
        setState(() {
          _isManipulatingImage = false;
        });
      }
    } else if (!_isDesktopMouseEvent(event.kind)) {
      _handleClickForReset(event.localPosition);
    }

    if (_activePointerKind == event.kind) {
      _activePointerKind = null;
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_activeMousePointer == event.pointer) {
      _activeMousePointer = null;
      _mouseMovedDuringGesture = false;

      if (mounted) {
        setState(() {
          _isManipulatingImage = false;
        });
      }
    }

    if (_activePointerKind == event.kind) {
      _activePointerKind = null;
    }
  }

  bool _isDesktopMouseEvent(PointerDeviceKind kind) {
    final isDesktopPlatform = switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux => true,
      _ => false,
    };

    return isDesktopPlatform && kind == PointerDeviceKind.mouse;
  }

  void _handleClickForReset(Offset localPosition) {
    final now = DateTime.now();
    final previousTime = _lastClickTime;
    final previousPosition = _lastClickPosition;

    final isDoubleClick =
        previousTime != null &&
        now.difference(previousTime) <= const Duration(milliseconds: 350) &&
        previousPosition != null &&
        (localPosition - previousPosition).distance <= 12;

    if (isDoubleClick) {
      _lastClickTime = null;
      _lastClickPosition = null;
      _resetImagePosition();
      return;
    }

    _lastClickTime = now;
    _lastClickPosition = localPosition;
  }

  _CropGeometry _geometryFor({
    required CropState crop,
    required Size frameSize,
  }) {
    final totalRotationDegrees =
        widget.transform.normalizedRotationDegrees + crop.straightenDegrees;

    return _CropGeometry(
      frameSize: frameSize,
      sourceAspectRatio: widget.sourceAspectRatio,
      radians: totalRotationDegrees * math.pi / 180,
    );
  }

  Offset _translationFor(CropState crop, Size frameSize) {
    return Offset(
      crop.offset.dx * frameSize.width,
      crop.offset.dy * frameSize.height,
    );
  }

  NormalizedCropOffset _normalizedOffsetFor(
    Offset translation,
    Size frameSize,
  ) {
    if (frameSize.width <= 0 || frameSize.height <= 0) {
      return NormalizedCropOffset.zero;
    }

    return NormalizedCropOffset(
      dx: translation.dx / frameSize.width,
      dy: translation.dy / frameSize.height,
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (_frameSize.isEmpty || _usesInvertedDesktopMousePan) {
      return;
    }

    _gestureStartCrop = widget.crop;
    _gestureStartFocalPoint =
        details.localFocalPoint - _frameSize.center(Offset.zero);

    setState(() {
      _isManipulatingImage = true;
    });
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final startCrop = _gestureStartCrop;
    final startFocal = _gestureStartFocalPoint;
    final frameSize = _frameSize;

    if (_usesInvertedDesktopMousePan ||
        startCrop == null ||
        startFocal == null ||
        frameSize.isEmpty) {
      return;
    }

    final newScale = (startCrop.scale * details.scale)
        .clamp(CropState.minimumScale, CropState.maximumScale)
        .toDouble();

    final scaleRatio = newScale / startCrop.scale;

    final startTranslation = _translationFor(startCrop, frameSize);
    final currentFocal =
        details.localFocalPoint - frameSize.center(Offset.zero);

    // Map the image point that was under the gesture's initial focal point to
    // the current focal point while applying the new zoom level. With one
    // pointer this naturally becomes a pan gesture; with two pointers it is
    // pan + pinch zoom.
    final proposedTranslation =
        currentFocal + ((startTranslation - startFocal) * scaleRatio);

    final geometry = _geometryFor(crop: startCrop, frameSize: frameSize);
    final clampedTranslation = geometry.clampTranslation(
      proposedTranslation,
      cropScale: newScale,
    );

    widget.onCropChanged(
      startCrop.copyWith(
        scale: newScale,
        offset: _normalizedOffsetFor(clampedTranslation, frameSize),
      ),
    );
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _gestureStartCrop = null;
    _gestureStartFocalPoint = null;

    if (mounted) {
      setState(() {
        _isManipulatingImage = false;
      });
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || _frameSize.isEmpty) {
      return;
    }

    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      if (resolved is! PointerScrollEvent || !mounted) {
        return;
      }

      final current = widget.crop;
      final oldScale = current.scale;

      final zoomFactor = resolved.scrollDelta.dy < 0 ? 1.1 : (1 / 1.1);

      final newScale = (oldScale * zoomFactor)
          .clamp(CropState.minimumScale, CropState.maximumScale)
          .toDouble();

      if ((newScale - oldScale).abs() < 0.000001) {
        return;
      }

      final frameSize = _frameSize;
      final focal = resolved.localPosition - frameSize.center(Offset.zero);
      final currentTranslation = _translationFor(current, frameSize);

      final scaleRatio = newScale / oldScale;

      // Keep the image content under the mouse pointer stable while zooming.
      final proposedTranslation =
          focal + ((currentTranslation - focal) * scaleRatio);

      final geometry = _geometryFor(crop: current, frameSize: frameSize);
      final clampedTranslation = geometry.clampTranslation(
        proposedTranslation,
        cropScale: newScale,
      );

      setState(() {
        _isManipulatingImage = true;
      });

      widget.onCropChanged(
        current.copyWith(
          scale: newScale,
          offset: _normalizedOffsetFor(clampedTranslation, frameSize),
        ),
      );

      // Wheel events do not expose a gesture-end callback. Return the grid to
      // its idle treatment shortly after the wheel burst finishes.
      _wheelIdleTimer?.cancel();
      _wheelIdleTimer = Timer(const Duration(milliseconds: 180), () {
        if (!mounted) {
          return;
        }

        setState(() {
          _isManipulatingImage = false;
        });
      });
    });
  }

  void _handleResizeStart(
    CropResizeHandle handle,
    DragStartDetails details,
    Size stageSize,
  ) {
    if (stageSize.isEmpty) {
      return;
    }

    _resizeStartCrop = widget.crop;
    _resizeStartGlobalPosition = details.globalPosition;
    _resizeStageSize = stageSize;
    _activeResizeHandle = handle;

    setState(() {
      _isResizingCrop = true;
    });
  }

  void _handleResizeUpdate(DragUpdateDetails details) {
    final startCrop = _resizeStartCrop;
    final startPosition = _resizeStartGlobalPosition;
    final handle = _activeResizeHandle;
    final stageSize = _resizeStageSize;

    if (startCrop == null ||
        startPosition == null ||
        handle == null ||
        stageSize.isEmpty) {
      return;
    }

    final pointerDelta = details.globalPosition - startPosition;

    const minimumFrameExtent = 56.0;

    final nextRect = CropResizeGeometry.resize(
      startRect: startCrop.normalizedRect,
      handle: handle,
      deltaX: pointerDelta.dx / stageSize.width,
      deltaY: pointerDelta.dy / stageSize.height,
      minimumWidth: (minimumFrameExtent / stageSize.width)
          .clamp(NormalizedCropRect.minimumExtent, 1.0)
          .toDouble(),
      minimumHeight: (minimumFrameExtent / stageSize.height)
          .clamp(NormalizedCropRect.minimumExtent, 1.0)
          .toDouble(),
    );

    if (nextRect == startCrop.normalizedRect) {
      return;
    }

    final startFrameSize = Size(
      startCrop.normalizedRect.width * stageSize.width,
      startCrop.normalizedRect.height * stageSize.height,
    );

    final nextFrameSize = Size(
      nextRect.width * stageSize.width,
      nextRect.height * stageSize.height,
    );

    if (startFrameSize.isEmpty || nextFrameSize.isEmpty) {
      return;
    }

    // Keep the rendered image at the same visual size while the crop frame is
    // resized around it. Shrinking the frame therefore tightens the crop
    // instead of merely drawing the same composition in a smaller widget.
    final frameScale = startFrameSize.width / nextFrameSize.width;
    final nextScale = (startCrop.scale * frameScale)
        .clamp(CropState.minimumScale, CropState.maximumScale)
        .toDouble();

    final startFrameCenter = _stageCenterFor(
      startCrop.normalizedRect,
      stageSize,
    );
    final nextFrameCenter = _stageCenterFor(nextRect, stageSize);

    final startTranslation = _translationFor(startCrop, startFrameSize);
    final absoluteImageCenter = startFrameCenter + startTranslation;
    final proposedTranslation = absoluteImageCenter - nextFrameCenter;

    final nextCrop = startCrop.copyWith(
      normalizedRect: nextRect,
      scale: nextScale,
    );

    final geometry = _geometryFor(crop: nextCrop, frameSize: nextFrameSize);
    final clampedTranslation = geometry.clampTranslation(
      proposedTranslation,
      cropScale: nextScale,
    );

    widget.onCropChanged(
      nextCrop.copyWith(
        offset: _normalizedOffsetFor(clampedTranslation, nextFrameSize),
      ),
    );
  }

  void _handleResizeEnd() {
    _resizeStartCrop = null;
    _resizeStartGlobalPosition = null;
    _resizeStageSize = Size.zero;
    _activeResizeHandle = null;

    if (mounted) {
      setState(() {
        _isResizingCrop = false;
      });
    }
  }

  Offset _stageCenterFor(NormalizedCropRect rect, Size stageSize) {
    return Offset(
      ((rect.left + rect.right) / 2) * stageSize.width,
      ((rect.top + rect.bottom) / 2) * stageSize.height,
    );
  }

  void _resetImagePosition() {
    widget.onCropChanged(
      widget.crop.copyWith(
        scale: CropState.minimumScale,
        offset: NormalizedCropOffset.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = math.max(1.0, constraints.maxWidth - 48);
        final availableHeight = math.max(1.0, constraints.maxHeight - 48);
        final sourceAspectRatio =
            widget.sourceAspectRatio.isFinite && widget.sourceAspectRatio > 0
            ? widget.sourceAspectRatio
            : 4 / 3;

        var stageWidth = availableWidth;
        var stageHeight = stageWidth / sourceAspectRatio;

        if (stageHeight > availableHeight) {
          stageHeight = availableHeight;
          stageWidth = stageHeight * sourceAspectRatio;
        }

        final stageSize = Size(stageWidth, stageHeight);
        final cropRect = widget.crop.normalizedRect.sanitized();
        final frameRect = Rect.fromLTRB(
          cropRect.left * stageWidth,
          cropRect.top * stageHeight,
          cropRect.right * stageWidth,
          cropRect.bottom * stageHeight,
        );
        final frameSize = frameRect.size;
        _frameSize = frameSize;

        return Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: ColoredBox(
                key: ValueKey('crop-canvas-background'),
                color: AppColors.canvas,
              ),
            ),
            Center(
              child: SizedBox(
                key: const ValueKey('crop-source-stage'),
                width: stageSize.width,
                height: stageSize.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fromRect(
                      rect: frameRect,
                      child: MouseRegion(
                        cursor: _isManipulatingImage
                            ? SystemMouseCursors.grabbing
                            : SystemMouseCursors.grab,
                        child: Listener(
                          key: const ValueKey('crop-interaction-surface'),
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: _handlePointerDown,
                          onPointerMove: _handlePointerMove,
                          onPointerUp: _handlePointerUp,
                          onPointerCancel: _handlePointerCancel,
                          onPointerSignal: _handlePointerSignal,
                          child: GestureDetector(
                            key: const ValueKey('crop-gesture-detector'),
                            behavior: HitTestBehavior.opaque,
                            onScaleStart: _handleScaleStart,
                            onScaleUpdate: _handleScaleUpdate,
                            onScaleEnd: _handleScaleEnd,
                            child: SizedBox(
                              key: const ValueKey('crop-frame'),
                              width: frameSize.width,
                              height: frameSize.height,
                              child: ClipRect(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _CropImagePreview(
                                      sourceImagePath: widget.sourceImagePath,
                                      adjustments: widget.adjustments,
                                      transform: widget.transform,
                                      crop: widget.crop,
                                      frameSize: frameSize,
                                      sourceAspectRatio:
                                          widget.sourceAspectRatio,
                                    ),
                                    IgnorePointer(
                                      child: CompositionGuideOverlay(
                                        guide: widget.compositionGuide,
                                        emphasize:
                                            _isManipulatingImage ||
                                            _isResizingCrop,
                                      ),
                                    ),
                                    const IgnorePointer(
                                      child: CustomPaint(
                                        painter: _CropFramePainter(),
                                      ),
                                    ),
                                    Positioned(
                                      right: AppSpacing.sm,
                                      bottom: AppSpacing.sm,
                                      child: IgnorePointer(
                                        child: _CropZoomBadge(
                                          scale: widget.crop.scale,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ..._buildResizeHandles(frameRect, stageSize),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildResizeHandles(Rect frameRect, Size stageSize) {
    const hitExtent = 36.0;
    const halfHitExtent = hitExtent / 2;

    Widget handle(
      CropResizeHandle resizeHandle,
      Offset center,
      MouseCursor cursor,
      String keyName,
    ) {
      final left = (center.dx - halfHitExtent)
          .clamp(0.0, math.max(0.0, stageSize.width - hitExtent))
          .toDouble();
      final top = (center.dy - halfHitExtent)
          .clamp(0.0, math.max(0.0, stageSize.height - hitExtent))
          .toDouble();

      return Positioned(
        left: left,
        top: top,
        width: hitExtent,
        height: hitExtent,
        child: MouseRegion(
          cursor: cursor,
          child: GestureDetector(
            key: ValueKey(keyName),
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onPanStart: (details) {
              _handleResizeStart(resizeHandle, details, stageSize);
            },
            onPanUpdate: _handleResizeUpdate,
            onPanEnd: (_) => _handleResizeEnd(),
            onPanCancel: _handleResizeEnd,
          ),
        ),
      );
    }

    return [
      handle(
        CropResizeHandle.topLeft,
        frameRect.topLeft,
        SystemMouseCursors.resizeUpLeftDownRight,
        'crop-resize-top-left',
      ),
      handle(
        CropResizeHandle.topRight,
        frameRect.topRight,
        SystemMouseCursors.resizeUpRightDownLeft,
        'crop-resize-top-right',
      ),
      handle(
        CropResizeHandle.bottomLeft,
        frameRect.bottomLeft,
        SystemMouseCursors.resizeUpRightDownLeft,
        'crop-resize-bottom-left',
      ),
      handle(
        CropResizeHandle.bottomRight,
        frameRect.bottomRight,
        SystemMouseCursors.resizeUpLeftDownRight,
        'crop-resize-bottom-right',
      ),
    ];
  }
}

class _CropImagePreview extends StatelessWidget {
  const _CropImagePreview({
    required this.sourceImagePath,
    required this.adjustments,
    required this.transform,
    required this.crop,
    required this.frameSize,
    required this.sourceAspectRatio,
  });

  final String sourceImagePath;
  final ImageAdjustments adjustments;
  final ImageTransform transform;
  final CropState crop;
  final Size frameSize;
  final double sourceAspectRatio;

  @override
  Widget build(BuildContext context) {
    final totalRotationDegrees =
        transform.normalizedRotationDegrees + crop.straightenDegrees;
    final radians = totalRotationDegrees * math.pi / 180;

    final geometry = _CropGeometry(
      frameSize: frameSize,
      sourceAspectRatio: sourceAspectRatio,
      radians: radians,
    );

    final visualScale = crop.scale * geometry.minimumCoverScale;

    final requestedTranslation = Offset(
      crop.offset.dx * frameSize.width,
      crop.offset.dy * frameSize.height,
    );

    final translation = geometry.clampTranslation(
      requestedTranslation,
      cropScale: crop.scale,
    );

    final previewTransform = ImageTransform(
      flipHorizontal: transform.flipHorizontal,
      flipVertical: transform.flipVertical,
    );

    return Transform.translate(
      key: const ValueKey('crop-image-translation'),
      offset: translation,
      child: Transform.rotate(
        key: const ValueKey('crop-image-straighten'),
        angle: radians,
        alignment: Alignment.center,
        child: Transform.scale(
          key: const ValueKey('crop-image-cover-scale'),
          scale: visualScale,
          alignment: Alignment.center,
          child: SizedBox(
            width: frameSize.width,
            height: frameSize.height,
            child: EditorRenderedImage(
              sourceImagePath: sourceImagePath,
              adjustments: adjustments,
              transform: previewTransform,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: AppColors.surfaceElevated,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textDisabled,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CropGeometry {
  const _CropGeometry({
    required this.frameSize,
    required this.sourceAspectRatio,
    required this.radians,
  });

  final Size frameSize;
  final double sourceAspectRatio;
  final double radians;

  double get _frameRatio => frameSize.width / frameSize.height;

  double get containedWidth {
    if (sourceAspectRatio >= _frameRatio) {
      return frameSize.width;
    }

    return frameSize.height * sourceAspectRatio;
  }

  double get containedHeight {
    if (sourceAspectRatio >= _frameRatio) {
      return frameSize.width / sourceAspectRatio;
    }

    return frameSize.height;
  }

  double get _cosine => math.cos(radians);
  double get _sine => math.sin(radians);

  double get _requiredLocalHalfWidth {
    return ((_cosine.abs() * frameSize.width) +
            (_sine.abs() * frameSize.height)) /
        2;
  }

  double get _requiredLocalHalfHeight {
    return ((_sine.abs() * frameSize.width) +
            (_cosine.abs() * frameSize.height)) /
        2;
  }

  double get minimumCoverScale {
    if (frameSize.width <= 0 ||
        frameSize.height <= 0 ||
        !sourceAspectRatio.isFinite ||
        sourceAspectRatio <= 0) {
      return 1;
    }

    final widthScale = (_requiredLocalHalfWidth * 2) / containedWidth;
    final heightScale = (_requiredLocalHalfHeight * 2) / containedHeight;

    return math.max(1.0, math.max(widthScale, heightScale));
  }

  Offset clampTranslation(
    Offset proposedTranslation, {
    required double cropScale,
  }) {
    final effectiveScale = minimumCoverScale * cropScale;

    final imageHalfWidth = containedWidth * effectiveScale / 2;
    final imageHalfHeight = containedHeight * effectiveScale / 2;

    final horizontalSlack = math.max(
      0.0,
      imageHalfWidth - _requiredLocalHalfWidth,
    );

    final verticalSlack = math.max(
      0.0,
      imageHalfHeight - _requiredLocalHalfHeight,
    );

    // Express the requested translation in the image's rotated local axes.
    final localX =
        (proposedTranslation.dx * _cosine) + (proposedTranslation.dy * _sine);

    final localY =
        (-proposedTranslation.dx * _sine) + (proposedTranslation.dy * _cosine);

    final clampedLocalX = localX
        .clamp(-horizontalSlack, horizontalSlack)
        .toDouble();

    final clampedLocalY = localY
        .clamp(-verticalSlack, verticalSlack)
        .toDouble();

    // Transform the clamped local translation back into frame coordinates.
    return Offset(
      (_cosine * clampedLocalX) - (_sine * clampedLocalY),
      (_sine * clampedLocalX) + (_cosine * clampedLocalY),
    );
  }
}

class _CropZoomBadge extends StatelessWidget {
  const _CropZoomBadge({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB310151A),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          '${(scale * 100).round()}%',
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _CropFramePainter extends CustomPainter {
  const _CropFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const borderColor = Color(0xD9FFFFFF);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    final handlePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      borderPaint,
    );

    const handleLength = 18.0;

    canvas.drawLine(Offset.zero, const Offset(handleLength, 0), handlePaint);
    canvas.drawLine(Offset.zero, const Offset(0, handleLength), handlePaint);

    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - handleLength, 0),
      handlePaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, handleLength),
      handlePaint,
    );

    canvas.drawLine(
      Offset(0, size.height),
      Offset(handleLength, size.height),
      handlePaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - handleLength),
      handlePaint,
    );

    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - handleLength, size.height),
      handlePaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - handleLength),
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CropFramePainter oldDelegate) => false;
}

class _CropWorkspaceControls extends StatelessWidget {
  const _CropWorkspaceControls({
    required this.compact,
    required this.crop,
    required this.transform,
    required this.originalAspectRatio,
    required this.selectedRatioId,
    required this.ratioOptions,
    required this.selectedGuide,
    required this.onSelectRatio,
    required this.onSelectGuide,
    required this.onSwapRatioOrientation,
    required this.onStraightenChanged,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onFlipHorizontal,
    required this.onFlipVertical,
  });

  final bool compact;
  final CropState crop;
  final ImageTransform transform;
  final double? originalAspectRatio;
  final String selectedRatioId;
  final List<_CropRatioOption> ratioOptions;
  final CompositionGuideType selectedGuide;
  final ValueChanged<_CropRatioOption> onSelectRatio;
  final ValueChanged<CompositionGuideType> onSelectGuide;
  final VoidCallback onSwapRatioOrientation;
  final ValueChanged<double> onStraightenChanged;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onFlipHorizontal;
  final VoidCallback onFlipVertical;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.surface,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          compact ? AppSpacing.sm : AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 38,
              child: Row(
                children: [
                  Expanded(
                    child: ListView.separated(
                      key: const ValueKey('crop-ratio-list'),
                      scrollDirection: Axis.horizontal,
                      itemCount: ratioOptions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final option = ratioOptions[index];
                        final isOriginal = option.id == 'original';
                        final isSelected = selectedRatioId == option.id;

                        return ChoiceChip(
                          key: ValueKey('crop-ratio-${option.id}'),
                          label: Text(
                            _displayRatioLabel(
                              option,
                              isSelected: isSelected,
                              currentRatio: crop.aspectRatio,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: isOriginal && originalAspectRatio == null
                              ? null
                              : (_) {
                                  onSelectRatio(option);
                                },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    key: const ValueKey('crop-swap-ratio-orientation'),
                    tooltip: 'Swap crop orientation',
                    onPressed:
                        crop.aspectRatio == null ||
                            _isClose(crop.aspectRatio!, 1)
                        ? null
                        : onSwapRatioOrientation,
                    icon: const Icon(Icons.screen_rotation_alt),
                  ),
                  PopupMenuButton<CompositionGuideType>(
                    key: const ValueKey('composition-guide-menu'),
                    tooltip: 'Composition guide: ${selectedGuide.label}',
                    initialValue: selectedGuide,
                    onSelected: onSelectGuide,
                    icon: const Icon(Icons.grid_on),
                    itemBuilder: (context) => [
                      CheckedPopupMenuItem<CompositionGuideType>(
                        key: const ValueKey('composition-guide-none'),
                        value: CompositionGuideType.none,
                        checked: selectedGuide == CompositionGuideType.none,
                        child: Text(CompositionGuideType.none.label),
                      ),
                      CheckedPopupMenuItem<CompositionGuideType>(
                        key: const ValueKey('composition-guide-rule-of-thirds'),
                        value: CompositionGuideType.ruleOfThirds,
                        checked:
                            selectedGuide == CompositionGuideType.ruleOfThirds,
                        child: Text(CompositionGuideType.ruleOfThirds.label),
                      ),
                      CheckedPopupMenuItem<CompositionGuideType>(
                        key: const ValueKey(
                          'composition-guide-center-symmetry',
                        ),
                        value: CompositionGuideType.centerSymmetry,
                        checked:
                            selectedGuide ==
                            CompositionGuideType.centerSymmetry,
                        child: Text(CompositionGuideType.centerSymmetry.label),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const SizedBox(
                  width: 76,
                  child: Text('Straighten', style: AppTypography.label),
                ),
                Expanded(
                  child: Slider(
                    key: const ValueKey('crop-straighten-slider'),
                    min: CropState.minimumStraightenDegrees,
                    max: CropState.maximumStraightenDegrees,
                    divisions: 900,
                    value: crop.straightenDegrees,
                    onChanged: onStraightenChanged,
                  ),
                ),
                SizedBox(
                  width: 58,
                  child: Text(
                    _formatDegrees(crop.straightenDegrees),
                    textAlign: TextAlign.right,
                    style: AppTypography.label,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CropTransformButton(
                  key: const ValueKey('crop-rotate-left'),
                  icon: Icons.rotate_left,
                  tooltip: 'Rotate left 90°',
                  onPressed: onRotateLeft,
                ),
                _CropTransformButton(
                  key: const ValueKey('crop-rotate-right'),
                  icon: Icons.rotate_right,
                  tooltip: 'Rotate right 90°',
                  onPressed: onRotateRight,
                ),
                _CropTransformButton(
                  key: const ValueKey('crop-flip-horizontal'),
                  icon: Icons.flip,
                  tooltip: transform.flipHorizontal
                      ? 'Horizontal flip on'
                      : 'Flip horizontally',
                  isActive: transform.flipHorizontal,
                  onPressed: onFlipHorizontal,
                ),
                _CropTransformButton(
                  key: const ValueKey('crop-flip-vertical'),
                  icon: Icons.flip,
                  tooltip: transform.flipVertical
                      ? 'Vertical flip on'
                      : 'Flip vertically',
                  isActive: transform.flipVertical,
                  quarterTurns: 1,
                  onPressed: onFlipVertical,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _displayRatioLabel(
    _CropRatioOption option, {
    required bool isSelected,
    required double? currentRatio,
  }) {
    final optionRatio = option.ratio;

    if (!isSelected || currentRatio == null || optionRatio == null) {
      return option.label;
    }

    if (_isClose(currentRatio, optionRatio)) {
      return option.label;
    }

    if (_isClose(currentRatio, 1 / optionRatio)) {
      final parts = option.label.split(':');

      if (parts.length == 2) {
        return '${parts[1]}:${parts[0]}';
      }
    }

    return option.label;
  }

  static bool _isClose(double a, double b) => (a - b).abs() < 0.000001;

  static String _formatDegrees(double value) {
    final rounded = (value * 10).round() / 10;
    final text = rounded == rounded.round()
        ? rounded.round().toString()
        : rounded.toStringAsFixed(1);

    return rounded > 0 ? '+$text°' : '$text°';
  }
}

class _CropTransformButton extends StatelessWidget {
  const _CropTransformButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.quarterTurns = 0,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: isActive ? AppColors.accent : AppColors.textSecondary,
        backgroundColor: isActive ? AppColors.accentMuted : null,
      ),
      icon: RotatedBox(quarterTurns: quarterTurns, child: Icon(icon)),
    );
  }
}

class _CropRatioOption {
  const _CropRatioOption({required this.id, required this.label, this.ratio});

  final String id;
  final String label;
  final double? ratio;
}
