class PresetCurvePointValues {
  const PresetCurvePointValues({required this.input, required this.output});

  final double input;
  final double output;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresetCurvePointValues &&
          input == other.input &&
          output == other.output;

  @override
  int get hashCode => Object.hash(input, output);
}

class PresetToneCurveValues {
  PresetToneCurveValues({required Iterable<PresetCurvePointValues> points})
    : points = List.unmodifiable(points);

  final List<PresetCurvePointValues> points;

  static final PresetToneCurveValues identity = PresetToneCurveValues(
    points: const [
      PresetCurvePointValues(input: 0, output: 0),
      PresetCurvePointValues(input: 1, output: 1),
    ],
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PresetToneCurveValues ||
        points.length != other.points.length) {
      return false;
    }
    for (var index = 0; index < points.length; index += 1) {
      if (points[index] != other.points[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(points);
}

class PresetToneCurvesValues {
  PresetToneCurvesValues({
    required this.master,
    required this.red,
    required this.green,
    required this.blue,
  });

  final PresetToneCurveValues master;
  final PresetToneCurveValues red;
  final PresetToneCurveValues green;
  final PresetToneCurveValues blue;

  static final PresetToneCurvesValues initial = PresetToneCurvesValues(
    master: PresetToneCurveValues.identity,
    red: PresetToneCurveValues.identity,
    green: PresetToneCurveValues.identity,
    blue: PresetToneCurveValues.identity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresetToneCurvesValues &&
          master == other.master &&
          red == other.red &&
          green == other.green &&
          blue == other.blue;

  @override
  int get hashCode => Object.hash(master, red, green, blue);
}
