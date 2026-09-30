import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/curve_point.dart';
import 'package:presetstudio/features/editor/domain/tone_curves.dart';

void main() {
  group('CurvePoint', () {
    test('clamps coordinates to normalized range', () {
      final point = CurvePoint(input: -0.5, output: 1.5);

      expect(point.input, 0);
      expect(point.output, 1);
    });

    test('sanitizes non-finite coordinates', () {
      final point = CurvePoint(input: double.nan, output: double.infinity);

      expect(point.input, 0);
      expect(point.output, 0);
    });

    test('supports value equality', () {
      expect(
        CurvePoint(input: 0.25, output: 0.75),
        CurvePoint(input: 0.25, output: 0.75),
      );
    });
  });

  group('ToneCurve', () {
    test('identity contains normalized black and white endpoints', () {
      expect(ToneCurve.identity.points, [
        CurvePoint(input: 0, output: 0),
        CurvePoint(input: 1, output: 1),
      ]);
      expect(ToneCurve.identity.isIdentity, isTrue);
    });

    test('adds missing endpoints and sorts points by input', () {
      final curve = ToneCurve(
        points: [
          CurvePoint(input: 0.75, output: 0.6),
          CurvePoint(input: 0.25, output: 0.4),
        ],
      );

      expect(curve.points, [
        CurvePoint(input: 0, output: 0),
        CurvePoint(input: 0.25, output: 0.4),
        CurvePoint(input: 0.75, output: 0.6),
        CurvePoint(input: 1, output: 1),
      ]);
    });

    test('preserves explicit endpoint output values', () {
      final curve = ToneCurve(
        points: [
          CurvePoint(input: 0, output: 0.1),
          CurvePoint(input: 1, output: 0.9),
        ],
      );

      expect(curve.points.first.output, 0.1);
      expect(curve.points.last.output, 0.9);
      expect(curve.isIdentity, isFalse);
    });

    test('keeps the last point when inputs are duplicated', () {
      final curve = ToneCurve(
        points: [
          CurvePoint(input: 0.5, output: 0.25),
          CurvePoint(input: 0.5, output: 0.75),
        ],
      );

      expect(curve.points.length, 3);
      expect(curve.points[1], CurvePoint(input: 0.5, output: 0.75));
    });

    test('exposes an unmodifiable point collection', () {
      final curve = ToneCurve.identity;

      expect(
        () => curve.points.add(CurvePoint(input: 0.5, output: 0.5)),
        throwsUnsupportedError,
      );
    });

    test('supports value equality independent of input order', () {
      final first = ToneCurve(
        points: [
          CurvePoint(input: 0.25, output: 0.2),
          CurvePoint(input: 0.75, output: 0.8),
        ],
      );
      final second = ToneCurve(
        points: [
          CurvePoint(input: 0.75, output: 0.8),
          CurvePoint(input: 0.25, output: 0.2),
        ],
      );

      expect(first, second);
    });
  });

  group('ToneCurves', () {
    test('initial state contains identity curves for every channel', () {
      final curves = ToneCurves.initial;

      expect(curves.master, ToneCurve.identity);
      expect(curves.red, ToneCurve.identity);
      expect(curves.green, ToneCurve.identity);
      expect(curves.blue, ToneCurve.identity);
      expect(curves.isDefault, isTrue);
    });

    test('detects a modified channel', () {
      final curves = ToneCurves.initial.copyWith(
        blue: ToneCurve(
          points: [
            CurvePoint(input: 0, output: 0.1),
            CurvePoint(input: 1, output: 0.9),
          ],
        ),
      );

      expect(curves.isDefault, isFalse);
      expect(curves.master.isIdentity, isTrue);
      expect(curves.blue.isIdentity, isFalse);
    });

    test('copyWith preserves untouched channels', () {
      final master = ToneCurve(points: [CurvePoint(input: 0.5, output: 0.6)]);
      final curves = ToneCurves.initial.copyWith(master: master);

      expect(curves.master, master);
      expect(curves.red, ToneCurve.identity);
      expect(curves.green, ToneCurve.identity);
      expect(curves.blue, ToneCurve.identity);
    });
  });
}
