import 'dart:math' as math;

import 'adjustment_type.dart';

class AdjustmentDefinition {
  const AdjustmentDefinition({
    required this.type,
    required this.label,
    required this.minValue,
    required this.maxValue,
    required this.defaultValue,
    required this.step,
  });

  final AdjustmentType type;
  final String label;

  final double minValue;
  final double maxValue;
  final double defaultValue;
  final double step;

  double clamp(double value) {
    return value.clamp(minValue, maxValue).toDouble();
  }

  double sanitize(double value) {
    final clampedValue = clamp(value);

    if (step <= 0) {
      return clampedValue;
    }

    final steps = ((clampedValue - minValue) / step).round();
    final snappedValue = minValue + (steps * step);

    final decimalPlaces = _decimalPlaces(step);
    final factor = math.pow(10, decimalPlaces).toDouble();

    final roundedValue = (snappedValue * factor).round() / factor;

    return clamp(roundedValue);
  }

  double normalize(double value) {
    final sanitizedValue = sanitize(value);

    if (sanitizedValue == defaultValue) {
      return 0;
    }

    if (sanitizedValue > defaultValue) {
      final positiveRange = maxValue - defaultValue;

      if (positiveRange == 0) {
        return 0;
      }

      return (sanitizedValue - defaultValue) / positiveRange;
    }

    final negativeRange = defaultValue - minValue;

    if (negativeRange == 0) {
      return 0;
    }

    return (sanitizedValue - defaultValue) / negativeRange;
  }

  static int _decimalPlaces(double value) {
    final text = value.toString();

    if (!text.contains('.')) {
      return 0;
    }

    return text.split('.').last.length;
  }
}

class AdjustmentDefinitions {
  const AdjustmentDefinitions._();

  static const Map<AdjustmentType, AdjustmentDefinition> values = {
    AdjustmentType.exposure: AdjustmentDefinition(
      type: AdjustmentType.exposure,
      label: 'Exposure',
      minValue: -5,
      maxValue: 5,
      defaultValue: 0,
      step: 0.1,
    ),
    AdjustmentType.contrast: AdjustmentDefinition(
      type: AdjustmentType.contrast,
      label: 'Contrast',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      step: 1,
    ),
    AdjustmentType.highlights: AdjustmentDefinition(
      type: AdjustmentType.highlights,
      label: 'Highlights',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      step: 1,
    ),
    AdjustmentType.shadows: AdjustmentDefinition(
      type: AdjustmentType.shadows,
      label: 'Shadows',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      step: 1,
    ),
    AdjustmentType.whites: AdjustmentDefinition(
      type: AdjustmentType.whites,
      label: 'Whites',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      step: 1,
    ),
    AdjustmentType.blacks: AdjustmentDefinition(
      type: AdjustmentType.blacks,
      label: 'Blacks',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      step: 1,
    ),
    AdjustmentType.temperature: AdjustmentDefinition(
      type: AdjustmentType.temperature,
      label: 'Temperature',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      step: 1,
    ),
    AdjustmentType.tint: AdjustmentDefinition(
      type: AdjustmentType.tint,
      label: 'Tint',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      step: 1,
    ),
    AdjustmentType.vibrance: AdjustmentDefinition(
      type: AdjustmentType.vibrance,
      label: 'Vibrance',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      step: 1,
    ),
    AdjustmentType.saturation: AdjustmentDefinition(
      type: AdjustmentType.saturation,
      label: 'Saturation',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      step: 1,
    ),
  };

  static AdjustmentDefinition of(AdjustmentType type) {
    return values[type]!;
  }
}
