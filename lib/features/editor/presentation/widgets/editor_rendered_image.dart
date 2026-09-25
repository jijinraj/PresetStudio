import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/image_adjustments.dart';
import '../../domain/image_transform.dart';
import '../../rendering/editor_render_pipeline.dart';
import 'editor_rotation_layout.dart';

class EditorRenderedImage extends StatefulWidget {
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

  @override
  State<EditorRenderedImage> createState() => _EditorRenderedImageState();
}

class _EditorRenderedImageState extends State<EditorRenderedImage> {
  static const EditorRenderPipeline _pipeline = EditorRenderPipeline();
  static const String _tonalShaderAsset = 'shaders/editor_tonal.frag';

  static Future<ui.FragmentProgram>? _tonalProgramFuture;

  ui.FragmentShader? _tonalShader;

  @override
  void initState() {
    super.initState();
    _prepareTonalShader();
  }

  Future<void> _prepareTonalShader() async {
    if (!ui.ImageFilter.isShaderFilterSupported) {
      return;
    }

    try {
      final program = await (_tonalProgramFuture ??=
          ui.FragmentProgram.fromAsset(_tonalShaderAsset));

      if (!mounted) {
        return;
      }

      setState(() {
        _tonalShader = program.fragmentShader();
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to load PresetStudio tonal shader. '
        'Falling back to the color-matrix renderer.\n'
        '$error\n$stackTrace',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final renderPlan = _pipeline.buildPlan(
      widget.adjustments,
      transform: widget.transform,
    );

    final sourceImage = Image.file(
      File(widget.sourceImagePath),
      fit: widget.fit,
      filterQuality: widget.filterQuality,
      gaplessPlayback: true,
      errorBuilder: widget.errorBuilder,
    );

    final flipScaleX = renderPlan.transform.flipHorizontal ? -1.0 : 1.0;
    final flipScaleY = renderPlan.transform.flipVertical ? -1.0 : 1.0;

    final filteredImage = _buildFilteredImage(
      sourceImage,
      renderPlan.adjustments,
      renderPlan.colorMatrix,
    );

    return RepaintBoundary(
      child: EditorRotationLayout(
        key: const ValueKey('editor-image-rotation'),
        rotationDegrees: renderPlan.transform.normalizedRotationDegrees,
        child: Transform(
          key: const ValueKey('editor-image-flip'),
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(flipScaleX, flipScaleY, 1.0),
          child: filteredImage,
        ),
      ),
    );
  }

  Widget _buildFilteredImage(
    Widget sourceImage,
    ImageAdjustments adjustments,
    List<double> fallbackColorMatrix,
  ) {
    final shader = _tonalShader;

    if (shader == null || !ui.ImageFilter.isShaderFilterSupported) {
      return ColorFiltered(
        key: const ValueKey('editor-color-filter'),
        colorFilter: ColorFilter.matrix(fallbackColorMatrix),
        child: sourceImage,
      );
    }

    _configureTonalShader(shader, adjustments);

    return ImageFiltered(
      key: const ValueKey('editor-color-filter'),
      imageFilter: ui.ImageFilter.shader(shader),
      child: sourceImage,
    );
  }

  void _configureTonalShader(
    ui.FragmentShader shader,
    ImageAdjustments adjustments,
  ) {
    // Float slots 0 and 1 belong to u_size and are supplied automatically
    // by ImageFilter.shader.
    shader.setFloat(2, adjustments.exposure);
    shader.setFloat(3, adjustments.contrast);
    shader.setFloat(4, adjustments.highlights);
    shader.setFloat(5, adjustments.shadows);
    shader.setFloat(6, adjustments.whites);
    shader.setFloat(7, adjustments.blacks);
    shader.setFloat(8, adjustments.temperature);
    shader.setFloat(9, adjustments.tint);
    shader.setFloat(10, adjustments.vibrance);
    shader.setFloat(11, adjustments.saturation);
  }
}
