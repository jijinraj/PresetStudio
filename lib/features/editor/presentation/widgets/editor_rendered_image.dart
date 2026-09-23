import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/image_adjustments.dart';
import '../../domain/image_transform.dart';
import '../../rendering/editor_render_pipeline.dart';

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

    return RepaintBoundary(
      child: RotatedBox(
        key: const ValueKey('editor-image-rotation'),
        quarterTurns: renderPlan.transform.rotationQuarterTurns,
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(renderPlan.colorMatrix),
          child: sourceImage,
        ),
      ),
    );
  }
}
