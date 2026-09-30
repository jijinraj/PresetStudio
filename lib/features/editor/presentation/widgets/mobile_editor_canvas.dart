import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_radii.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../domain/crop_state.dart';
import '../../domain/image_adjustments.dart';
import '../../domain/image_transform.dart';
import '../../domain/tone_curves.dart';
import 'editor_image_viewport.dart';

/// Image-first mobile editor workspace.
///
/// This widget owns mobile-only presentation decisions around the shared
/// [EditorImageViewport]: spacing, adaptive contain-fit behaviour, and the
/// rounded-image language. Rendering, transform, crop, zoom, comparison and
/// gesture behaviour remain in the existing editor widgets.
class MobileEditorCanvas extends StatelessWidget {
  const MobileEditorCanvas({
    required this.sourceImagePath,
    required this.adjustments,
    required this.transform,
    required this.crop,
    required this.onImportImage,
    required this.isImporting,
    this.toneCurves,
    this.topAction,
    this.imageOverlay,
    this.onTap,
    this.onHorizontalSwipe,
    super.key,
  });

  final String? sourceImagePath;
  final ImageAdjustments adjustments;
  final ImageTransform transform;
  final CropState crop;
  final ToneCurves? toneCurves;
  final Future<void> Function() onImportImage;
  final bool isImporting;
  final Widget? topAction;
  final Widget? imageOverlay;
  final VoidCallback? onTap;
  final ValueChanged<EditorViewportSwipeDirection>? onHorizontalSwipe;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('mobile-editor-canvas'),
      color: AppColors.canvas,
      child: Padding(
        key: const ValueKey('mobile-editor-canvas-frame'),
        padding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: AppSpacing.sm,
        ),
        child: EditorImageViewport(
          sourceImagePath: sourceImagePath,
          adjustments: adjustments,
          transform: transform,
          crop: crop,
          toneCurves: toneCurves,
          onImportImage: onImportImage,
          isImporting: isImporting,
          compactZoomControls: true,
          contentPadding: EdgeInsets.zero,
          imageFit: BoxFit.contain,
          imageBorderRadius: BorderRadius.circular(AppRadii.editorImage),
          imageOverlay: imageOverlay,
          onTap: onTap,
          onHorizontalSwipe: onHorizontalSwipe,
          topAction: topAction,
        ),
      ),
    );
  }
}
