import 'dart:math' as math;

import 'adjustment_type.dart';

class AdjustmentDefinition {
  const AdjustmentDefinition({
    required this.type,
    required this.label,
    required this.minValue,
    required this.maxValue,
    required this.defaultValue,
    required this.precisionStep,
    required this.interactionStep,
    required this.coarseStep,
  });

  final AdjustmentType type;
  final String label;

  final double minValue;
  final double maxValue;
  final double defaultValue;

  /// Smallest value PresetStudio can represent for this adjustment.
  ///
  /// This controls sanitization, direct numeric entry precision,
  /// and fine keyboard/mouse interaction.
  final double precisionStep;

  /// Standard increment used by normal keyboard, mouse-wheel,
  /// and slider interaction.
  final double interactionStep;

  /// Larger increment intended for accelerated desktop interaction.
  final double coarseStep;

  double clamp(double value) {
    return value.clamp(minValue, maxValue).toDouble();
  }

  double sanitize(double value) {
    final clampedValue = clamp(value);

    if (precisionStep <= 0) {
      return clampedValue;
    }

    final steps = ((clampedValue - minValue) / precisionStep).round();

    final snappedValue = minValue + (steps * precisionStep);

    final decimalPlaces = _decimalPlaces(precisionStep);

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
      precisionStep: 0.01,
      interactionStep: 0.1,
      coarseStep: 0.5,
    ),
    AdjustmentType.contrast: AdjustmentDefinition(
      type: AdjustmentType.contrast,
      label: 'Contrast',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      precisionStep: 1,
      interactionStep: 1,
      coarseStep: 10,
    ),
    AdjustmentType.highlights: AdjustmentDefinition(
      type: AdjustmentType.highlights,
      label: 'Highlights',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      precisionStep: 1,
      interactionStep: 1,
      coarseStep: 10,
    ),
    AdjustmentType.shadows: AdjustmentDefinition(
      type: AdjustmentType.shadows,
      label: 'Shadows',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      precisionStep: 1,
      interactionStep: 1,
      coarseStep: 10,
    ),
    AdjustmentType.whites: AdjustmentDefinition(
      type: AdjustmentType.whites,
      label: 'Whites',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      precisionStep: 1,
      interactionStep: 1,
      coarseStep: 10,
    ),
    AdjustmentType.blacks: AdjustmentDefinition(
      type: AdjustmentType.blacks,
      label: 'Blacks',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      precisionStep: 1,
      interactionStep: 1,
      coarseStep: 10,
    ),
    AdjustmentType.temperature: AdjustmentDefinition(
      type: AdjustmentType.temperature,
      label: 'Temperature',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      precisionStep: 1,
      interactionStep: 1,
      coarseStep: 10,
    ),
    AdjustmentType.tint: AdjustmentDefinition(
      type: AdjustmentType.tint,
      label: 'Tint',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      precisionStep: 1,
      interactionStep: 1,
      coarseStep: 10,
    ),
    AdjustmentType.vibrance: AdjustmentDefinition(
      type: AdjustmentType.vibrance,
      label: 'Vibrance',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      precisionStep: 1,
      interactionStep: 1,
      coarseStep: 10,
    ),
    AdjustmentType.saturation: AdjustmentDefinition(
      type: AdjustmentType.saturation,
      label: 'Saturation',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      precisionStep: 1,
      interactionStep: 1,
      coarseStep: 10,
    ),
    AdjustmentType.vignetteAmount: AdjustmentDefinition(
      type: AdjustmentType.vignetteAmount,
      label: 'Vignette',
      minValue: -100,
      maxValue: 100,
      defaultValue: 0,
      precisionStep: 1,
      interactionStep: 1,
      coarseStep: 10,
    ),
    AdjustmentType.vignetteFeather: AdjustmentDefinition(
      type: AdjustmentType.vignetteFeather,
      label: 'Vignette Feather',
      minValue: 0,
      maxValue: 100,
      defaultValue: 50,
      precisionStep: 1,
      interactionStep: 1,
      coarseStep: 10,
    ),
  };

  static AdjustmentDefinition of(AdjustmentType type) {
    return values[type]!;
  }
}
