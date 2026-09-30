class PresetHslColorAdjustmentValues {
  const PresetHslColorAdjustmentValues({
    this.hue = 0,
    this.saturation = 0,
    this.luminance = 0,
  });

  final double hue;
  final double saturation;
  final double luminance;

  static const PresetHslColorAdjustmentValues neutral =
      PresetHslColorAdjustmentValues();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PresetHslColorAdjustmentValues &&
            hue == other.hue &&
            saturation == other.saturation &&
            luminance == other.luminance;
  }

  @override
  int get hashCode => Object.hash(hue, saturation, luminance);
}

class PresetHslColorMixerValues {
  const PresetHslColorMixerValues({
    this.red = PresetHslColorAdjustmentValues.neutral,
    this.orange = PresetHslColorAdjustmentValues.neutral,
    this.yellow = PresetHslColorAdjustmentValues.neutral,
    this.green = PresetHslColorAdjustmentValues.neutral,
    this.aqua = PresetHslColorAdjustmentValues.neutral,
    this.blue = PresetHslColorAdjustmentValues.neutral,
    this.purple = PresetHslColorAdjustmentValues.neutral,
    this.magenta = PresetHslColorAdjustmentValues.neutral,
  });

  final PresetHslColorAdjustmentValues red;
  final PresetHslColorAdjustmentValues orange;
  final PresetHslColorAdjustmentValues yellow;
  final PresetHslColorAdjustmentValues green;
  final PresetHslColorAdjustmentValues aqua;
  final PresetHslColorAdjustmentValues blue;
  final PresetHslColorAdjustmentValues purple;
  final PresetHslColorAdjustmentValues magenta;

  static const PresetHslColorMixerValues initial = PresetHslColorMixerValues();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PresetHslColorMixerValues &&
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
