import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/curve_point.dart';
import 'package:presetstudio/features/editor/domain/tone_curves.dart';
import 'package:presetstudio/features/editor/rendering/tone_curve_lut.dart';

void main() {
  group('ToneCurveLut', () {
    test('identity curves produce identity channel samples', () {
      final lut = ToneCurveLut.fromToneCurves(ToneCurves.initial);

      expect(lut.red, hasLength(ToneCurveLut.sampleCount));
      expect(lut.green, hasLength(ToneCurveLut.sampleCount));
      expect(lut.blue, hasLength(ToneCurveLut.sampleCount));

      for (var index = 0; index < ToneCurveLut.sampleCount; index += 1) {
        final expected = index / (ToneCurveLut.sampleCount - 1);
        expect(lut.red[index], closeTo(expected, 0.000001));
        expect(lut.green[index], closeTo(expected, 0.000001));
        expect(lut.blue[index], closeTo(expected, 0.000001));
      }
    });

    test('evaluates linearly between control points', () {
      final curve = ToneCurve(points: [CurvePoint(input: 0.5, output: 0.75)]);

      expect(ToneCurveLut.evaluate(curve, 0.25), closeTo(0.375, 0.000001));
      expect(ToneCurveLut.evaluate(curve, 0.75), closeTo(0.875, 0.000001));
    });

    test('composes master before individual RGB channels', () {
      final curves = ToneCurves.initial.copyWith(
        master: ToneCurve(points: [CurvePoint(input: 0.5, output: 0.75)]),
        red: ToneCurve(points: [CurvePoint(input: 0.75, output: 0.5)]),
      );

      final lut = ToneCurveLut.fromToneCurves(curves);
      final middleIndex = 8;
      final input = middleIndex / (ToneCurveLut.sampleCount - 1);
      final masterOutput = ToneCurveLut.evaluate(curves.master, input);

      expect(
        lut.red[middleIndex],
        closeTo(ToneCurveLut.evaluate(curves.red, masterOutput), 0.000001),
      );
      expect(lut.green[middleIndex], closeTo(masterOutput, 0.000001));
      expect(lut.blue[middleIndex], closeTo(masterOutput, 0.000001));
    });

    test('channel-only curve leaves other channels unchanged', () {
      final curves = ToneCurves.initial.copyWith(
        blue: ToneCurve(points: [CurvePoint(input: 0.5, output: 0.8)]),
      );

      final lut = ToneCurveLut.fromToneCurves(curves);

      for (var index = 0; index < ToneCurveLut.sampleCount; index += 1) {
        final expected = index / (ToneCurveLut.sampleCount - 1);
        expect(lut.red[index], closeTo(expected, 0.000001));
        expect(lut.green[index], closeTo(expected, 0.000001));
      }

      expect(lut.blue, isNot(lut.red));
    });

    test('samples LUT with the same adjacent interpolation as the shader', () {
      final samples = List<double>.generate(
        ToneCurveLut.sampleCount,
        (index) => index == 8 ? 1.0 : 0.0,
      );
      final halfway = 7.5 / (ToneCurveLut.sampleCount - 1);

      expect(ToneCurveLut.sample(samples, halfway), closeTo(0.5, 0.000001));
      expect(ToneCurveLut.sample(samples, -1), 0);
      expect(ToneCurveLut.sample(samples, 2), 0);
    });
  });
}
