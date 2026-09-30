import '../domain/tone_curves.dart';

class ToneCurveLut {
  const ToneCurveLut({
    required this.red,
    required this.green,
    required this.blue,
  });

  static const int sampleCount = 16;

  final List<double> red;
  final List<double> green;
  final List<double> blue;

  factory ToneCurveLut.fromToneCurves(ToneCurves curves) {
    return ToneCurveLut(
      red: _buildChannel(curves.master, curves.red),
      green: _buildChannel(curves.master, curves.green),
      blue: _buildChannel(curves.master, curves.blue),
    );
  }

  static List<double> _buildChannel(ToneCurve master, ToneCurve channel) {
    return List<double>.unmodifiable(
      List<double>.generate(sampleCount, (index) {
        final input = index / (sampleCount - 1);
        final masterOutput = evaluate(master, input);
        return evaluate(channel, masterOutput);
      }),
    );
  }

  static double evaluate(ToneCurve curve, double input) {
    final value = input.clamp(0.0, 1.0).toDouble();
    final points = curve.points;

    for (var index = 1; index < points.length; index += 1) {
      final right = points[index];

      if (value > right.input) {
        continue;
      }

      final left = points[index - 1];
      final span = right.input - left.input;

      if (span <= 0) {
        return right.output;
      }

      final t = (value - left.input) / span;
      return left.output + ((right.output - left.output) * t);
    }

    return points.last.output;
  }
}
