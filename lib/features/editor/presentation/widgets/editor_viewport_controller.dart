import 'package:flutter/material.dart';

class EditorViewportController extends ChangeNotifier {
  EditorViewportController() {
    transformationController.addListener(_handleTransformChanged);
  }

  static const double minimumScale = 1.0;
  static const double maximumScale = 8.0;
  static const double doubleTapScale = 2.0;
  static const double _zoomStep = 1.25;
  static const double _epsilon = 0.001;

  final TransformationController transformationController =
      TransformationController();

  double get scale => transformationController.value.getMaxScaleOnAxis();

  int get percentage => (scale * 100).round();

  bool get isFitted => (scale - minimumScale).abs() <= _epsilon;

  bool get canZoomIn => scale < maximumScale - _epsilon;

  bool get canZoomOut => scale > minimumScale + _epsilon;

  void zoomIn({required Offset focalPoint, required Size viewportSize}) {
    setScale(
      scale * _zoomStep,
      focalPoint: focalPoint,
      viewportSize: viewportSize,
    );
  }

  void zoomOut({required Offset focalPoint, required Size viewportSize}) {
    setScale(
      scale / _zoomStep,
      focalPoint: focalPoint,
      viewportSize: viewportSize,
    );
  }

  void toggleDoubleTapZoom({
    required Offset focalPoint,
    required Size viewportSize,
  }) {
    if (isFitted) {
      setScale(
        doubleTapScale,
        focalPoint: focalPoint,
        viewportSize: viewportSize,
      );
    } else {
      reset();
    }
  }

  void setScale(
    double nextScale, {
    required Offset focalPoint,
    required Size viewportSize,
  }) {
    final targetScale = nextScale.clamp(minimumScale, maximumScale).toDouble();

    if ((targetScale - minimumScale).abs() <= _epsilon) {
      reset();
      return;
    }

    final scenePoint = transformationController.toScene(focalPoint);

    final unclampedTranslation = Offset(
      focalPoint.dx - (scenePoint.dx * targetScale),
      focalPoint.dy - (scenePoint.dy * targetScale),
    );

    final maxTranslationX = (targetScale - 1.0) * viewportSize.width;
    final maxTranslationY = (targetScale - 1.0) * viewportSize.height;

    final translation = Offset(
      unclampedTranslation.dx.clamp(-maxTranslationX, 0.0).toDouble(),
      unclampedTranslation.dy.clamp(-maxTranslationY, 0.0).toDouble(),
    );

    transformationController.value = Matrix4.identity()
      ..setEntry(0, 0, targetScale)
      ..setEntry(1, 1, targetScale)
      ..setTranslationRaw(translation.dx, translation.dy, 0.0);
  }

  void reset() {
    transformationController.value = Matrix4.identity();
  }

  void _handleTransformChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    transformationController.removeListener(_handleTransformChanged);
    transformationController.dispose();
    super.dispose();
  }
}
