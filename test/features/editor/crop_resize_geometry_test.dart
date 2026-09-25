import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/crop_resize_geometry.dart';
import 'package:presetstudio/features/editor/domain/crop_state.dart';

void main() {
  const start = NormalizedCropRect(
    left: 0.2,
    top: 0.1,
    right: 0.8,
    bottom: 0.9,
  );

  NormalizedCropRect resize(
    CropResizeHandle handle, {
    double deltaX = 0,
    double deltaY = 0,
    double minimumWidth = 0.05,
    double minimumHeight = 0.05,
  }) {
    return CropResizeGeometry.resize(
      startRect: start,
      handle: handle,
      deltaX: deltaX,
      deltaY: deltaY,
      minimumWidth: minimumWidth,
      minimumHeight: minimumHeight,
    );
  }

  void expectRatioPreserved(NormalizedCropRect rect) {
    expect(rect.width / rect.height, closeTo(start.width / start.height, 1e-9));
  }

  group('CropResizeGeometry', () {
    test('top-left keeps bottom-right anchored and preserves ratio', () {
      final result = resize(
        CropResizeHandle.topLeft,
        deltaX: 0.08,
        deltaY: 0.06,
      );

      expect(result.right, closeTo(start.right, 1e-9));
      expect(result.bottom, closeTo(start.bottom, 1e-9));
      expect(result.left, greaterThan(start.left));
      expect(result.top, greaterThan(start.top));
      expectRatioPreserved(result);
    });

    test('top-right keeps bottom-left anchored and preserves ratio', () {
      final result = resize(
        CropResizeHandle.topRight,
        deltaX: -0.08,
        deltaY: 0.06,
      );

      expect(result.left, closeTo(start.left, 1e-9));
      expect(result.bottom, closeTo(start.bottom, 1e-9));
      expect(result.right, lessThan(start.right));
      expect(result.top, greaterThan(start.top));
      expectRatioPreserved(result);
    });

    test('bottom-left keeps top-right anchored and preserves ratio', () {
      final result = resize(
        CropResizeHandle.bottomLeft,
        deltaX: 0.08,
        deltaY: -0.06,
      );

      expect(result.right, closeTo(start.right, 1e-9));
      expect(result.top, closeTo(start.top, 1e-9));
      expect(result.left, greaterThan(start.left));
      expect(result.bottom, lessThan(start.bottom));
      expectRatioPreserved(result);
    });

    test('bottom-right keeps top-left anchored and preserves ratio', () {
      final result = resize(
        CropResizeHandle.bottomRight,
        deltaX: -0.08,
        deltaY: -0.06,
      );

      expect(result.left, closeTo(start.left, 1e-9));
      expect(result.top, closeTo(start.top, 1e-9));
      expect(result.right, lessThan(start.right));
      expect(result.bottom, lessThan(start.bottom));
      expectRatioPreserved(result);
    });

    test('outward resize remains inside normalized bounds', () {
      final result = resize(CropResizeHandle.topLeft, deltaX: -10, deltaY: -10);

      expect(result.left, greaterThanOrEqualTo(0));
      expect(result.top, greaterThanOrEqualTo(0));
      expect(result.right, lessThanOrEqualTo(1));
      expect(result.bottom, lessThanOrEqualTo(1));
      expectRatioPreserved(result);
    });

    test('inward resize respects the requested minimum size', () {
      final result = resize(
        CropResizeHandle.bottomRight,
        deltaX: -10,
        deltaY: -10,
        minimumWidth: 0.18,
        minimumHeight: 0.16,
      );

      expect(result.width, greaterThanOrEqualTo(0.18 - 1e-9));
      expect(result.height, greaterThanOrEqualTo(0.16 - 1e-9));
      expectRatioPreserved(result);
    });
  });
}
