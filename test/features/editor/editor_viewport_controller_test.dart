import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_viewport_controller.dart';

void main() {
  group('EditorViewportController', () {
    test('starts fitted at one hundred percent', () {
      final controller = EditorViewportController();
      addTearDown(controller.dispose);

      expect(controller.isFitted, isTrue);
      expect(controller.scale, closeTo(1.0, 0.000001));
      expect(controller.percentage, 100);
      expect(controller.canZoomOut, isFalse);
      expect(controller.canZoomIn, isTrue);
    });

    test('zooms in and out around a focal point', () {
      final controller = EditorViewportController();
      addTearDown(controller.dispose);

      const viewportSize = Size(800, 600);
      const focalPoint = Offset(400, 300);

      controller.zoomIn(focalPoint: focalPoint, viewportSize: viewportSize);

      expect(controller.scale, closeTo(1.25, 0.000001));
      expect(controller.percentage, 125);

      controller.zoomOut(focalPoint: focalPoint, viewportSize: viewportSize);

      expect(controller.isFitted, isTrue);
      expect(controller.scale, closeTo(1.0, 0.000001));
    });

    test('clamps zoom to supported range', () {
      final controller = EditorViewportController();
      addTearDown(controller.dispose);

      const viewportSize = Size(800, 600);
      const focalPoint = Offset(400, 300);

      controller.setScale(
        100,
        focalPoint: focalPoint,
        viewportSize: viewportSize,
      );

      expect(
        controller.scale,
        closeTo(EditorViewportController.maximumScale, 0.000001),
      );

      controller.setScale(
        0.1,
        focalPoint: focalPoint,
        viewportSize: viewportSize,
      );

      expect(controller.isFitted, isTrue);
    });

    test('manual pan applies supplied x and y deltas', () {
      final controller = EditorViewportController();
      addTearDown(controller.dispose);

      const viewportSize = Size(800, 600);
      const focalPoint = Offset(400, 300);

      controller.setScale(
        2.0,
        focalPoint: focalPoint,
        viewportSize: viewportSize,
      );

      final before = controller.transformationController.value.clone();

      controller.panBy(const Offset(40, 30), viewportSize: viewportSize);

      final after = controller.transformationController.value;

      expect(after.storage[12] - before.storage[12], closeTo(40, 0.000001));
      expect(after.storage[13] - before.storage[13], closeTo(30, 0.000001));
    });

    test('manual pan is ignored while fitted', () {
      final controller = EditorViewportController();
      addTearDown(controller.dispose);

      controller.panBy(
        const Offset(40, 30),
        viewportSize: const Size(800, 600),
      );

      expect(controller.transformationController.value, Matrix4.identity());
    });

    test('double tap toggles useful zoom and fit', () {
      final controller = EditorViewportController();
      addTearDown(controller.dispose);

      const viewportSize = Size(800, 600);
      const focalPoint = Offset(200, 150);

      controller.toggleDoubleTapZoom(
        focalPoint: focalPoint,
        viewportSize: viewportSize,
      );

      expect(
        controller.scale,
        closeTo(EditorViewportController.doubleTapScale, 0.000001),
      );

      controller.toggleDoubleTapZoom(
        focalPoint: focalPoint,
        viewportSize: viewportSize,
      );

      expect(controller.isFitted, isTrue);
    });
  });
}
