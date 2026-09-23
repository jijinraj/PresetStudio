import 'package:flutter/material.dart';

import '../../domain/adjustment_definition.dart';

class AdjustmentControl extends StatelessWidget {
  const AdjustmentControl({
    required this.definition,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final AdjustmentDefinition definition;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final sanitizedValue = definition.sanitize(value);
    final isDefault = sanitizedValue == definition.defaultValue;
    final divisions = _calculateDivisions(definition);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                definition.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              _formatValue(sanitizedValue, definition.step),
              key: ValueKey('adjustment-${definition.type.name}-value'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!isDefault) ...[
              const SizedBox(width: 4),
              IconButton(
                key: ValueKey('adjustment-${definition.type.name}-reset'),
                onPressed: enabled
                    ? () => onChanged(definition.defaultValue)
                    : null,
                tooltip: 'Reset ${definition.label}',
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ],
          ],
        ),
        Slider(
          key: ValueKey('adjustment-${definition.type.name}-slider'),
          value: sanitizedValue,
          min: definition.minValue,
          max: definition.maxValue,
          divisions: divisions,
          onChanged: enabled
              ? (nextValue) {
                  onChanged(definition.sanitize(nextValue));
                }
              : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatLimit(definition.minValue, definition.step),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              _formatLimit(definition.maxValue, definition.step),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  int _calculateDivisions(AdjustmentDefinition definition) {
    final range = definition.maxValue - definition.minValue;

    return (range / definition.step).round();
  }

  String _formatValue(double value, double step) {
    final formatted = _formatNumber(value, step);

    if (value > 0) {
      return '+$formatted';
    }

    return formatted;
  }

  String _formatLimit(double value, double step) {
    final formatted = _formatNumber(value, step);

    if (value > 0) {
      return '+$formatted';
    }

    return formatted;
  }

  String _formatNumber(double value, double step) {
    if (step >= 1.0) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }
}
