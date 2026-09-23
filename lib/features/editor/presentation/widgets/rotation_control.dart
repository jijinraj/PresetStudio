import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_spacing.dart';
import '../../domain/image_transform.dart';
import 'scalar_control.dart';

class RotationControl extends StatelessWidget {
  const RotationControl({
    required this.transform,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final ImageTransform transform;
  final ValueChanged<ImageTransform> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScalarControl(
          controlId: 'rotation',
          label: 'Rotation',
          value: transform.normalizedRotationDegrees,
          minValue: -180.0,
          maxValue: 180.0,
          defaultValue: 0.0,
          precisionStep: 0.1,
          interactionStep: 1.0,
          coarseStep: 15.0,
          valueSuffix: '°',
          sanitize: _sanitizeRotation,
          onChanged: (value) {
            onChanged(transform.copyWith(rotationDegrees: value));
          },
          enabled: enabled,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message: 'Rotate left 90°',
                child: OutlinedButton.icon(
                  key: const ValueKey('rotation-left-90'),
                  onPressed: enabled
                      ? () {
                          onChanged(transform.rotateCounterClockwise());
                        }
                      : null,
                  icon: const Icon(Icons.rotate_left, size: 18),
                  label: const Text('90°'),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Tooltip(
                message: 'Rotate right 90°',
                child: OutlinedButton.icon(
                  key: const ValueKey('rotation-right-90'),
                  onPressed: enabled
                      ? () {
                          onChanged(transform.rotateClockwise());
                        }
                      : null,
                  icon: const Icon(Icons.rotate_right, size: 18),
                  label: const Text('90°'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _sanitizeRotation(double value) {
    if (!value.isFinite) {
      return 0.0;
    }

    final clamped = value.clamp(-180.0, 180.0);

    final rounded = (clamped * 10.0).round() / 10.0;

    if (rounded == 0.0) {
      return 0.0;
    }

    return rounded;
  }
}
