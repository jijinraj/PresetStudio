import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';

class BeforeAfterButton extends StatelessWidget {
  const BeforeAfterButton({
    required this.enabled,
    required this.isShowingBefore,
    required this.onPreviewStart,
    required this.onPreviewEnd,
    this.compact = false,
    super.key,
  });

  final bool enabled;
  final bool isShowingBefore;
  final VoidCallback onPreviewStart;
  final VoidCallback onPreviewEnd;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.textDisabled
        : isShowingBefore
        ? AppColors.accent
        : AppColors.textSecondary;

    return Listener(
      onPointerDown: enabled ? (_) => onPreviewStart() : null,
      onPointerUp: enabled ? (_) => onPreviewEnd() : null,
      onPointerCancel: enabled ? (_) => onPreviewEnd() : null,
      child: IconButton(
        onPressed: enabled ? () {} : null,
        tooltip: 'Hold to view before',
        visualDensity: compact ? VisualDensity.compact : null,
        padding: compact ? EdgeInsets.zero : null,
        icon: Icon(
          isShowingBefore ? Icons.visibility : Icons.visibility_outlined,
          color: color,
          size: compact ? 20 : null,
        ),
      ),
    );
  }
}
