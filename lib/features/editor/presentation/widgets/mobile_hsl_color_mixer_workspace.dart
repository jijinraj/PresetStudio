import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../application/editor_controller.dart';
import '../../application/editor_history_entry.dart';
import '../../domain/hsl_color_mixer.dart';
import 'editor_rendered_image.dart';
import 'hsl_color_mixer_editor.dart';

class MobileHslColorMixerWorkspace extends StatefulWidget {
  const MobileHslColorMixerWorkspace({
    required this.controller,
    required this.onClose,
    super.key,
  });

  final EditorController controller;
  final VoidCallback onClose;

  @override
  State<MobileHslColorMixerWorkspace> createState() =>
      _MobileHslColorMixerWorkspaceState();
}

class _MobileHslColorMixerWorkspaceState
    extends State<MobileHslColorMixerWorkspace> {
  bool _ownsTransaction = false;
  bool _finalized = false;

  EditorController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_finalized) _ensureTransactionStarted();
    });
  }

  void _ensureTransactionStarted() {
    if (_ownsTransaction || controller.isEditTransactionActive) return;
    controller.beginSemanticEditTransaction(
      label: 'HSL Color Mixer',
      action: EditorHistoryAction.adjustment,
    );
    _ownsTransaction = true;
  }

  void _cancel() {
    if (_finalized) return;
    _finalized = true;
    if (_ownsTransaction && controller.isEditTransactionActive) {
      controller.cancelEditTransaction();
    }
    widget.onClose();
  }

  void _done() {
    if (_finalized) return;
    _ensureTransactionStarted();
    _finalized = true;
    if (_ownsTransaction && controller.isEditTransactionActive) {
      controller.endEditTransaction();
    }
    widget.onClose();
  }

  void _resetAll() {
    _ensureTransactionStarted();
    controller.updateHslColorMixer(HslColorMixer.initial);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final source = controller.session.sourceImagePath;
              if (source == null) {
                return const Center(child: Text('No image selected'));
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Row(
                      children: [
                        IconButton(
                          key: const ValueKey('mobile-color-mixer-cancel'),
                          tooltip: 'Cancel',
                          onPressed: _cancel,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            'Color Mixer',
                            textAlign: TextAlign.center,
                            style: AppTypography.title,
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('mobile-color-mixer-reset-all'),
                          tooltip: 'Reset color mixer',
                          onPressed: controller.session.hslColorMixer.isDefault
                              ? null
                              : _resetAll,
                          icon: const Icon(Icons.restart_alt_rounded),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        FilledButton(
                          key: const ValueKey('mobile-color-mixer-done'),
                          onPressed: _done,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: EdgeInsets.zero,
                            shape: const CircleBorder(),
                          ),
                          child: const Icon(Icons.check_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.xs,
                        AppSpacing.sm,
                        AppSpacing.sm,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final previewHeight = (constraints.maxHeight * 0.55)
                              .clamp(180.0, 430.0);

                          return Column(
                            children: [
                              SizedBox(
                                height: previewHeight,
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: ColoredBox(
                                    color: AppColors.surface,
                                    child: EditorRenderedImage(
                                      sourceImagePath: source,
                                      adjustments:
                                          controller.session.adjustments,
                                      transform: controller.session.transform,
                                      toneCurves: controller
                                          .session
                                          .effectiveToneCurves,
                                      hslColorMixer:
                                          controller.session.hslColorMixer,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: HslColorMixerEditor(
                                    key: const ValueKey(
                                      'mobile-hsl-color-mixer-editor',
                                    ),
                                    colorMixer:
                                        controller.session.hslColorMixer,
                                    onChanged: controller.updateHslColorMixer,
                                    compact: true,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
