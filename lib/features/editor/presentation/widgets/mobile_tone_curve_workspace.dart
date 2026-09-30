import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../application/editor_controller.dart';
import '../../application/editor_history_entry.dart';
import '../../domain/tone_curves.dart';
import '../../rendering/image_histogram.dart';
import 'editor_rendered_image.dart';
import 'tone_curve_editor.dart';
import 'tone_curve_histogram.dart';

class MobileToneCurveWorkspace extends StatefulWidget {
  const MobileToneCurveWorkspace({
    required this.controller,
    required this.onClose,
    super.key,
  });

  final EditorController controller;
  final VoidCallback onClose;

  @override
  State<MobileToneCurveWorkspace> createState() =>
      _MobileToneCurveWorkspaceState();
}

class _MobileToneCurveWorkspaceState extends State<MobileToneCurveWorkspace> {
  bool _ownsTransaction = false;
  bool _finalized = false;
  late final Future<ImageHistogram?> _histogram;

  EditorController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    final path = controller.session.sourceImagePath;
    _histogram = path == null
        ? Future<ImageHistogram?>.value()
        : File(path).readAsBytes().then(ImageHistogram.fromBytes);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_finalized) _ensureTransactionStarted();
    });
  }

  void _ensureTransactionStarted() {
    if (_ownsTransaction || controller.isEditTransactionActive) return;
    controller.beginSemanticEditTransaction(
      label: 'Tone Curves',
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
    controller.updateToneCurves(ToneCurves.initial);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _cancel();
        }
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

              return FutureBuilder<ImageHistogram?>(
                future: _histogram,
                builder: (context, snapshot) {
                  final histogram = snapshot.data;
                  final aspectRatio = histogram?.aspectRatio ?? 1.0;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xs,
                          AppSpacing.xs,
                          AppSpacing.xs,
                          AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              key: const ValueKey('mobile-curves-cancel'),
                              tooltip: 'Cancel',
                              onPressed: _cancel,
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            Expanded(
                              child: Text(
                                'Curves',
                                textAlign: TextAlign.center,
                                style: AppTypography.title,
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('mobile-curves-reset-all'),
                              tooltip: 'Reset all curves',
                              onPressed:
                                  controller
                                      .session
                                      .effectiveToneCurves
                                      .isDefault
                                  ? null
                                  : _resetAll,
                              icon: const Icon(Icons.restart_alt_rounded),
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            FilledButton(
                              key: const ValueKey('mobile-curves-done'),
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
                          child: ToneCurveEditor(
                            toneCurves: controller.session.effectiveToneCurves,
                            onChanged: controller.updateToneCurves,
                            mobileOverlay: true,
                            graphAspectRatio: aspectRatio,
                            graphBackgroundBuilder: (channel) => Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: EditorRenderedImage(
                                    sourceImagePath: source,
                                    adjustments: controller.session.adjustments,
                                    transform: controller.session.transform,
                                    toneCurves:
                                        controller.session.effectiveToneCurves,
                                    hslColorMixer:
                                        controller.session.hslColorMixer,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                if (histogram != null)
                                  ToneCurveHistogram(
                                    histogram: histogram,
                                    channel: channel,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
