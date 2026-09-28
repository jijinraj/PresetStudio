import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_radii.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';

/// Shared floating host for contextual mobile editor tools.
///
/// The host owns only presentation: placement, rounded surface treatment,
/// close affordance, and enter/exit motion. Tool-specific state remains with
/// the existing editor/preset controllers and the child supplied by the
/// mobile editor shell.
class MobileEditorToolPanel extends StatelessWidget {
  const MobileEditorToolPanel({
    required this.visible,
    required this.title,
    required this.child,
    required this.onClose,
    this.maxHeight = 340,
    super.key,
  });

  final bool visible;
  final String title;
  final Widget child;
  final VoidCallback onClose;
  final double maxHeight;

  static const Duration transitionDuration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        duration: transitionDuration,
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, 0.08),
        child: AnimatedOpacity(
          duration: transitionDuration,
          curve: Curves.easeOut,
          opacity: visible ? 1 : 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              key: const ValueKey('mobile-context-tool-panel'),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(AppRadii.editorPanel),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.editorPanel),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.xs,
                        AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(title, style: AppTypography.title),
                          ),
                          IconButton(
                            key: const ValueKey('mobile-context-panel-close'),
                            onPressed: onClose,
                            tooltip: 'Close $title',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
