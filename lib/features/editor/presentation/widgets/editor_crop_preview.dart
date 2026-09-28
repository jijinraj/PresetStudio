import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/crop_state.dart';
import '../../domain/image_adjustments.dart';
import '../../domain/image_transform.dart';
import 'editor_rendered_image.dart';

/// Renders the committed, non-destructive crop composition outside the
/// dedicated Crop & Straighten workspace.
///
/// Crop workspace zoom/pan is stored in [CropState]. This widget replays that
/// same composition in the normal editor so Done produces the exact crop the
/// user approved instead of falling back to the uncropped source image.
class EditorCropPreview extends StatefulWidget {
  const EditorCropPreview({
    required this.sourceImagePath,
    required this.adjustments,
    required this.transform,
    required this.crop,
    this.filterQuality = FilterQuality.medium,
    this.uncroppedFit = BoxFit.contain,
    this.errorBuilder,
    super.key,
  });

  final String sourceImagePath;
  final ImageAdjustments adjustments;
  final ImageTransform transform;
  final CropState crop;
  final FilterQuality filterQuality;
  final BoxFit uncroppedFit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  State<EditorCropPreview> createState() => _EditorCropPreviewState();
}

class _EditorCropPreviewState extends State<EditorCropPreview> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  double? _sourceAspectRatio;

  @override
  void initState() {
    super.initState();
    _resolveSourceAspectRatio();
  }

  @override
  void didUpdateWidget(covariant EditorCropPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.sourceImagePath != widget.sourceImagePath) {
      _detachImageStream();
      _sourceAspectRatio = null;
      _resolveSourceAspectRatio();
    }
  }

  @override
  void dispose() {
    _detachImageStream();
    super.dispose();
  }

  void _resolveSourceAspectRatio() {
    final provider = FileImage(File(widget.sourceImagePath));
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

        if (_sourceAspectRatio == ratio) {
          return;
        }

        setState(() {
          _sourceAspectRatio = ratio;
        });
      },
      onError: (error, stackTrace) {
        // EditorRenderedImage owns the visible image-load error. The crop
        // preview uses a neutral ratio fallback until dimensions are known.
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

  @override
  Widget build(BuildContext context) {
    final crop = widget.crop.sanitized();

    // Preserve the existing renderer exactly when no crop geometry exists.
    // This avoids changing ordinary rotation/fit behavior for uncropped images.
    if (crop.isDefault) {
      return EditorRenderedImage(
        sourceImagePath: widget.sourceImagePath,
        adjustments: widget.adjustments,
        transform: widget.transform,
        fit: widget.uncroppedFit,
        filterQuality: widget.filterQuality,
        errorBuilder: widget.errorBuilder,
      );
    }

    final sourceAspectRatio = _sourceAspectRatio ?? 4 / 3;
    final outputAspectRatio = _outputAspectRatio(crop, sourceAspectRatio);

    return AspectRatio(
      key: const ValueKey('editor-crop-output-frame'),
      aspectRatio: outputAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final frameSize = Size(constraints.maxWidth, constraints.maxHeight);

          final totalRotationDegrees =
              widget.transform.normalizedRotationDegrees +
              crop.straightenDegrees;

          final radians = totalRotationDegrees * math.pi / 180;

          final geometry = _CommittedCropGeometry(
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

          // Crop geometry owns visible rotation for the committed composition.
          // The low-level renderer keeps flips and tonal rendering, while
          // ordinary rotation + straighten are combined here exactly as in the
          // crop workspace.
          final previewTransform = ImageTransform(
            flipHorizontal: widget.transform.flipHorizontal,
            flipVertical: widget.transform.flipVertical,
          );

          return ClipRect(
            child: Transform.translate(
              key: const ValueKey('editor-crop-output-translation'),
              offset: translation,
              child: Transform.rotate(
                key: const ValueKey('editor-crop-output-rotation'),
                angle: radians,
                alignment: Alignment.center,
                child: Transform.scale(
                  key: const ValueKey('editor-crop-output-scale'),
                  scale: visualScale,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: frameSize.width,
                    height: frameSize.height,
                    child: EditorRenderedImage(
                      sourceImagePath: widget.sourceImagePath,
                      adjustments: widget.adjustments,
                      transform: previewTransform,
                      fit: BoxFit.contain,
                      filterQuality: widget.filterQuality,
                      errorBuilder: widget.errorBuilder,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static double _outputAspectRatio(CropState crop, double sourceAspectRatio) {
    final explicitRatio = crop.aspectRatio;

    if (explicitRatio != null && explicitRatio.isFinite && explicitRatio > 0) {
      return explicitRatio;
    }

    final rect = crop.normalizedRect.sanitized();

    if (rect.height <= 0) {
      return sourceAspectRatio;
    }

    return (sourceAspectRatio * rect.width / rect.height)
        .clamp(0.1, 10.0)
        .toDouble();
  }
}

class _CommittedCropGeometry {
  const _CommittedCropGeometry({
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

    return Offset(
      (_cosine * clampedLocalX) - (_sine * clampedLocalY),
      (_sine * clampedLocalX) + (_cosine * clampedLocalY),
    );
  }
}
