import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/image_adjustments.dart';
import '../../domain/image_transform.dart';
import '../../rendering/editor_render_pipeline.dart';
import 'editor_rotation_layout.dart';

class EditorRenderedImage extends StatelessWidget {
  const EditorRenderedImage({
    required this.sourceImagePath,
    required this.adjustments,
    required this.transform,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.medium,
    this.errorBuilder,
    super.key,
  });

  final String sourceImagePath;
  final ImageAdjustments adjustments;
  final ImageTransform transform;

  final BoxFit fit;
  final FilterQuality filterQuality;

  final ImageErrorWidgetBuilder? errorBuilder;

  static const EditorRenderPipeline _pipeline = EditorRenderPipeline();

  @override
  Widget build(BuildContext context) {
    final renderPlan = _pipeline.buildPlan(adjustments, transform: transform);

    final sourceImage = Image.file(
      File(sourceImagePath),
      fit: fit,
      filterQuality: filterQuality,
      gaplessPlayback: true,
      errorBuilder: errorBuilder,
    );

    final flipScaleX = renderPlan.transform.flipHorizontal ? -1.0 : 1.0;

    final flipScaleY = renderPlan.transform.flipVertical ? -1.0 : 1.0;

    return RepaintBoundary(
      child: EditorRotationLayout(
        key: const ValueKey('editor-image-rotation'),
        rotationDegrees: renderPlan.transform.normalizedRotationDegrees,
        child: Transform(
          key: const ValueKey('editor-image-flip'),
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(flipScaleX, flipScaleY, 1.0),
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(renderPlan.colorMatrix),
            child: sourceImage,
          ),
        ),
      ),
    );
  }
}
