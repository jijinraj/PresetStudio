import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_radii.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../application/editor_controller.dart';

class EditorHistoryList extends StatelessWidget {
  const EditorHistoryList({required this.controller, super.key});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.session.hasImage) {
          return const Text(
            'Open an image to start building edit history.',
            style: AppTypography.bodyMuted,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: controller.history.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.xxs),
          itemBuilder: (context, index) {
            final entry = controller.history[index];

            final isCurrent = index == controller.historyIndex;

            return Container(
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.accentMuted : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: InkWell(
                key: ValueKey('history-entry-$index'),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                onTap: isCurrent
                    ? null
                    : () {
                        controller.jumpToHistory(index);
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCurrent ? Icons.check_circle : Icons.circle_outlined,
                        size: 14,
                        color: isCurrent
                            ? AppColors.accent
                            : AppColors.textDisabled,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          entry.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMuted.copyWith(
                            color: isCurrent
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
