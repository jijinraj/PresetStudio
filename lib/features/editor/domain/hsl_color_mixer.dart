enum HslColorRange { red, orange, yellow, green, aqua, blue, purple, magenta }

class HslColorAdjustment {
  const HslColorAdjustment._({
    required this.hue,
    required this.saturation,
    required this.luminance,
  });

  factory HslColorAdjustment({
    double hue = 0,
    double saturation = 0,
    double luminance = 0,
  }) {
    return HslColorAdjustment._(
      hue: _sanitize(hue),
      saturation: _sanitize(saturation),
      luminance: _sanitize(luminance),
    );
  }

  final double hue;
  final double saturation;
  final double luminance;

  static const double minimumValue = -100;
  static const double maximumValue = 100;
  static const HslColorAdjustment neutral = HslColorAdjustment._(
    hue: 0,
    saturation: 0,
    luminance: 0,
  );

  bool get isNeutral => this == neutral;

  HslColorAdjustment copyWith({
    double? hue,
    double? saturation,
    double? luminance,
  }) {
    return HslColorAdjustment(
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      luminance: luminance ?? this.luminance,
    );
  }

  static double _sanitize(double value) {
    if (!value.isFinite) {
      return 0;
    }

    return value.clamp(minimumValue, maximumValue).toDouble();
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HslColorAdjustment &&
            hue == other.hue &&
            saturation == other.saturation &&
            luminance == other.luminance;
  }

  @override
  int get hashCode => Object.hash(hue, saturation, luminance);
}

class HslColorMixer {
  const HslColorMixer({
    this.red = HslColorAdjustment.neutral,
    this.orange = HslColorAdjustment.neutral,
    this.yellow = HslColorAdjustment.neutral,
    this.green = HslColorAdjustment.neutral,
    this.aqua = HslColorAdjustment.neutral,
    this.blue = HslColorAdjustment.neutral,
    this.purple = HslColorAdjustment.neutral,
    this.magenta = HslColorAdjustment.neutral,
  });

  final HslColorAdjustment red;
  final HslColorAdjustment orange;
  final HslColorAdjustment yellow;
  final HslColorAdjustment green;
  final HslColorAdjustment aqua;
  final HslColorAdjustment blue;
  final HslColorAdjustment purple;
  final HslColorAdjustment magenta;

  static const HslColorMixer initial = HslColorMixer();

  bool get isDefault =>
      HslColorRange.values.every((range) => adjustmentFor(range).isNeutral);

  HslColorAdjustment adjustmentFor(HslColorRange range) {
    return switch (range) {
      HslColorRange.red => red,
      HslColorRange.orange => orange,
      HslColorRange.yellow => yellow,
      HslColorRange.green => green,
      HslColorRange.aqua => aqua,
      HslColorRange.blue => blue,
      HslColorRange.purple => purple,
      HslColorRange.magenta => magenta,
    };
  }

  HslColorMixer withAdjustment(
    HslColorRange range,
    HslColorAdjustment adjustment,
  ) {
    return switch (range) {
      HslColorRange.red => copyWith(red: adjustment),
      HslColorRange.orange => copyWith(orange: adjustment),
      HslColorRange.yellow => copyWith(yellow: adjustment),
      HslColorRange.green => copyWith(green: adjustment),
      HslColorRange.aqua => copyWith(aqua: adjustment),
      HslColorRange.blue => copyWith(blue: adjustment),
      HslColorRange.purple => copyWith(purple: adjustment),
      HslColorRange.magenta => copyWith(magenta: adjustment),
    };
  }

  HslColorMixer copyWith({
    HslColorAdjustment? red,
    HslColorAdjustment? orange,
    HslColorAdjustment? yellow,
    HslColorAdjustment? green,
    HslColorAdjustment? aqua,
    HslColorAdjustment? blue,
    HslColorAdjustment? purple,
    HslColorAdjustment? magenta,
  }) {
    return HslColorMixer(
      red: red ?? this.red,
      orange: orange ?? this.orange,
      yellow: yellow ?? this.yellow,
      green: green ?? this.green,
      aqua: aqua ?? this.aqua,
      blue: blue ?? this.blue,
      purple: purple ?? this.purple,
      magenta: magenta ?? this.magenta,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HslColorMixer &&
            red == other.red &&
            orange == other.orange &&
            yellow == other.yellow &&
            green == other.green &&
            aqua == other.aqua &&
            blue == other.blue &&
            purple == other.purple &&
            magenta == other.magenta;
  }

  @override
  int get hashCode =>
      Object.hash(red, orange, yellow, green, aqua, blue, purple, magenta);
}
