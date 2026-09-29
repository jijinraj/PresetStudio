import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_dimensions.dart';
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
    this.immersive = false,
    super.key,
  });

  final bool visible;
  final String title;
  final Widget child;
  final VoidCallback onClose;
  final double maxHeight;

  /// Hides panel chrome while preserving the child's layout position.
  /// Used by precision controls so the active ruler can remain stationary
  /// under the user's finger while the surrounding editor chrome disappears.
  final bool immersive;

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
            child: AnimatedContainer(
              key: const ValueKey('mobile-context-tool-panel'),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: immersive
                    ? Colors.transparent
                    : AppColors.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(AppRadii.editorPanel),
                border: immersive ? null : Border.all(color: AppColors.border),
                boxShadow: immersive
                    ? const []
                    : const [
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
                    IgnorePointer(
                      ignoring: immersive,
                      child: AnimatedOpacity(
                        key: const ValueKey('mobile-context-panel-header'),
                        duration: const Duration(milliseconds: 160),
                        opacity: immersive ? 0 : 1,
                        child: Padding(
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
                                key: const ValueKey(
                                  'mobile-context-panel-close',
                                ),
                                onPressed: onClose,
                                tooltip: 'Close $title',
                                style: IconButton.styleFrom(
                                  minimumSize: const Size.square(
                                    AppDimensions.mobileTouchTarget,
                                  ),
                                ),
                                icon: const Icon(Icons.close, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: immersive ? 0 : 1,
                      child: const Divider(height: 1),
                    ),
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
