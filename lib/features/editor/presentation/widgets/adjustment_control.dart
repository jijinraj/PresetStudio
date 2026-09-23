import 'package:flutter/material.dart';

import '../../domain/adjustment_definition.dart';
import 'scalar_control.dart';

class AdjustmentControl extends StatelessWidget {
  const AdjustmentControl({
    required this.definition,
    required this.value,
    required this.onChanged,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.enabled = true,
    super.key,
  });

  final AdjustmentDefinition definition;
  final double value;
  final ValueChanged<double> onChanged;

  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ScalarControl(
      controlId: 'adjustment-${definition.type.name}',
      label: definition.label,
      value: value,
      minValue: definition.minValue,
      maxValue: definition.maxValue,
      defaultValue: definition.defaultValue,
      precisionStep: definition.precisionStep,
      interactionStep: definition.interactionStep,
      coarseStep: definition.coarseStep,
      sanitize: definition.sanitize,
      onChanged: onChanged,
      onInteractionStart: onInteractionStart,
      onInteractionEnd: onInteractionEnd,
      enabled: enabled,
    );
  }
}
