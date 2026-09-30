class CurvePoint {
  const CurvePoint._({required this.input, required this.output});

  factory CurvePoint({required double input, required double output}) {
    return CurvePoint._(
      input: _sanitizeNormalized(input),
      output: _sanitizeNormalized(output),
    );
  }

  final double input;
  final double output;

  CurvePoint copyWith({double? input, double? output}) {
    return CurvePoint(
      input: input ?? this.input,
      output: output ?? this.output,
    );
  }

  static double _sanitizeNormalized(double value) {
    if (!value.isFinite) {
      return 0;
    }

    return value.clamp(0.0, 1.0).toDouble();
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CurvePoint && input == other.input && output == other.output;
  }

  @override
  int get hashCode => Object.hash(input, output);
}
