import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../domain/image_transform.dart';

class FlipControl extends StatelessWidget {
  const FlipControl({
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
        const Text('Flip', style: AppTypography.label),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _FlipButton(
                buttonKey: const ValueKey('flip-horizontal'),
                icon: Icons.swap_horiz,
                label: 'Horizontal',
                isActive: transform.flipHorizontal,
                onPressed: enabled
                    ? () {
                        onChanged(transform.toggleFlipHorizontal());
                      }
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _FlipButton(
                buttonKey: const ValueKey('flip-vertical'),
                icon: Icons.swap_vert,
                label: 'Vertical',
                isActive: transform.flipVertical,
                onPressed: enabled
                    ? () {
                        onChanged(transform.toggleFlipVertical());
                      }
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FlipButton extends StatelessWidget {
  const _FlipButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Flip $label',
      child: OutlinedButton(
        key: buttonKey,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isActive
              ? AppColors.accent
              : AppColors.textSecondary,
          backgroundColor: isActive
              ? AppColors.accentMuted
              : Colors.transparent,
          disabledForegroundColor: AppColors.textDisabled,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          visualDensity: VisualDensity.compact,
          side: BorderSide(
            color: isActive ? AppColors.accent : AppColors.borderStrong,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(label, maxLines: 1, softWrap: false),
            ],
          ),
        ),
      ),
    );
  }
}
