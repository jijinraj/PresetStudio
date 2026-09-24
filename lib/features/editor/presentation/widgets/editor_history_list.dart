import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_radii.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../application/editor_controller.dart';
import '../../application/editor_history_entry.dart';

class EditorHistoryList extends StatelessWidget {
  const EditorHistoryList({
    required this.controller,
    this.allowEditToggles = false,
    super.key,
  });

  final EditorController controller;

  /// Enables non-destructive apply/remove toggles for history operations.
  ///
  /// Mobile currently keeps the simpler chronological history presentation.
  final bool allowEditToggles;

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
          key: const ValueKey('editor-history-list'),
          padding: EdgeInsets.zero,
          itemCount: controller.history.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.xxs),
          itemBuilder: (context, index) {
            final entry = controller.history[index];
            final isCurrent = index == controller.historyIndex;
            final canToggle =
                allowEditToggles &&
                index > 0 &&
                entry.action != EditorHistoryAction.checkpoint;

            return Opacity(
              opacity: entry.isEnabled ? 1.0 : 0.52,
              child: Container(
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
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        if (canToggle)
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              key: ValueKey('history-entry-toggle-$index'),
                              onPressed: () {
                                controller.setHistoryEntryEnabled(
                                  index,
                                  !entry.isEnabled,
                                );
                              },
                              tooltip: entry.isEnabled
                                  ? 'Disable this edit'
                                  : 'Enable this edit',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              icon: Icon(
                                entry.isEnabled
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: entry.isEnabled
                                    ? AppColors.textSecondary
                                    : AppColors.textDisabled,
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: 28,
                            child: Icon(
                              isCurrent
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 14,
                              color: isCurrent
                                  ? AppColors.accent
                                  : AppColors.textDisabled,
                            ),
                          ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            entry.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMuted.copyWith(
                              color: isCurrent
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              decoration: entry.isEnabled
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        if (isCurrent && canToggle)
                          const Padding(
                            padding: EdgeInsets.only(left: AppSpacing.xxs),
                            child: Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppColors.accent,
                            ),
                          ),
                      ],
                    ),
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
