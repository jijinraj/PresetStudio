import 'curve_point.dart';

class ToneCurve {
  ToneCurve({required Iterable<CurvePoint> points})
    : points = List.unmodifiable(_sanitizePoints(points));

  ToneCurve._identity()
    : points = List.unmodifiable([
        CurvePoint(input: 0, output: 0),
        CurvePoint(input: 1, output: 1),
      ]);

  final List<CurvePoint> points;

  static final ToneCurve identity = ToneCurve._identity();

  bool get isIdentity => this == identity;

  ToneCurve copyWith({Iterable<CurvePoint>? points}) {
    return ToneCurve(points: points ?? this.points);
  }

  static List<CurvePoint> _sanitizePoints(Iterable<CurvePoint> points) {
    final byInput = <double, CurvePoint>{};

    for (final point in points) {
      final sanitized = CurvePoint(input: point.input, output: point.output);
      byInput[sanitized.input] = sanitized;
    }

    byInput.putIfAbsent(0, () => CurvePoint(input: 0, output: 0));
    byInput.putIfAbsent(1, () => CurvePoint(input: 1, output: 1));

    final sanitized = byInput.values.toList()
      ..sort((a, b) => a.input.compareTo(b.input));

    return sanitized;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! ToneCurve || points.length != other.points.length) {
      return false;
    }

    for (var index = 0; index < points.length; index += 1) {
      if (points[index] != other.points[index]) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode => Object.hashAll(points);
}

class ToneCurves {
  const ToneCurves({
    required this.master,
    required this.red,
    required this.green,
    required this.blue,
  });

  final ToneCurve master;
  final ToneCurve red;
  final ToneCurve green;
  final ToneCurve blue;

  static final ToneCurves initial = ToneCurves(
    master: ToneCurve.identity,
    red: ToneCurve.identity,
    green: ToneCurve.identity,
    blue: ToneCurve.identity,
  );

  bool get isDefault =>
      master.isIdentity &&
      red.isIdentity &&
      green.isIdentity &&
      blue.isIdentity;

  ToneCurves copyWith({
    ToneCurve? master,
    ToneCurve? red,
    ToneCurve? green,
    ToneCurve? blue,
  }) {
    return ToneCurves(
      master: master ?? this.master,
      red: red ?? this.red,
      green: green ?? this.green,
      blue: blue ?? this.blue,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ToneCurves &&
            master == other.master &&
            red == other.red &&
            green == other.green &&
            blue == other.blue;
  }

  @override
  int get hashCode => Object.hash(master, red, green, blue);
}
