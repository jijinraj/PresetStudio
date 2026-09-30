import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_dimensions.dart';
import '../../../../theme/tokens/app_radii.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../../presets/application/preset_adjustment_mapper.dart';
import '../../../presets/application/preset_library_controller.dart';
import '../../../presets/application/preset_remote_controller.dart';
import '../../../presets/domain/preset.dart';
import '../../../presets/domain/preset_record.dart';
import '../../../presets/presentation/widgets/mobile_preset_panel.dart';
import '../../application/editor_controller.dart';
import 'before_after_button.dart';
import 'composition_guide_controller.dart';
import 'composition_guide_overlay.dart';
import 'crop_workspace.dart';
import 'editor_history_list.dart';
import 'editor_image_viewport.dart';
import 'mobile_adjustment_panel.dart';
import 'mobile_editor_canvas.dart';
import 'mobile_editor_tool_panel.dart';
import 'mobile_guides_panel.dart';

enum _MobileMenuAction { history }

enum _MobileContextPanel { presets, adjust, guides }

class MobileEditorShell extends StatefulWidget {
  const MobileEditorShell({
    required this.controller,
    this.presetLibraryController,
    this.presetRemoteController,
    required this.onImportImage,
    required this.isImporting,
    this.onExportImage,
    this.isExporting = false,
    super.key,
  });

  final EditorController controller;
  final PresetLibraryController? presetLibraryController;
  final PresetRemoteController? presetRemoteController;
  final Future<void> Function() onImportImage;
  final bool isImporting;
  final Future<void> Function()? onExportImage;
  final bool isExporting;

  @override
  State<MobileEditorShell> createState() => _MobileEditorShellState();
}

class _MobileEditorShellState extends State<MobileEditorShell> {
  final Random _random = Random();
  late final CompositionGuideController _guideController;
  final List<String> _presetTrail = <String>[];
  final Set<String> _visitedPresetKeys = <String>{};
  final Set<String> _cyclePresetKeys = <String>{};

  String? _lastSourceImagePath;
  String? _lastObservedActivePresetId;
  int _presetTrailIndex = -1;
  int _applyGeneration = 0;
  bool _pendingInitialRandomPreset = false;
  bool _isApplyingPreset = false;
  bool _isPrecisionInteractionActive = false;
  _MobileContextPanel? _activeContextPanel;

  EditorController get controller => widget.controller;
  PresetLibraryController? get presetLibraryController =>
      widget.presetLibraryController;
  PresetRemoteController? get presetRemoteController =>
      widget.presetRemoteController;

  @override
  void initState() {
    super.initState();
    _guideController = CompositionGuideController();
    _guideController.addListener(_handleGuideChanged);
    _lastSourceImagePath = controller.session.sourceImagePath;
    _lastObservedActivePresetId = controller.session.activePresetId;
    _attachListeners();

    if (_lastSourceImagePath != null) {
      _resetPresetSession(autoApply: true);
    }
  }

  @override
  void didUpdateWidget(covariant MobileEditorShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller ||
        oldWidget.presetLibraryController != widget.presetLibraryController ||
        oldWidget.presetRemoteController != widget.presetRemoteController) {
      _detachListeners(oldWidget);
      _lastSourceImagePath = controller.session.sourceImagePath;
      _lastObservedActivePresetId = controller.session.activePresetId;
      _attachListeners();
      _resetPresetSession(autoApply: controller.session.hasImage);
    }
  }

  @override
  void dispose() {
    _detachListeners(widget);
    _guideController.removeListener(_handleGuideChanged);
    _guideController.dispose();
    super.dispose();
  }

  void _handleGuideChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _attachListeners() {
    controller.addListener(_handleEditorChanged);
    presetLibraryController?.addListener(_handlePresetSourcesChanged);
    presetRemoteController?.addListener(_handlePresetSourcesChanged);
  }

  void _detachListeners(MobileEditorShell shell) {
    shell.controller.removeListener(_handleEditorChanged);
    shell.presetLibraryController?.removeListener(_handlePresetSourcesChanged);
    shell.presetRemoteController?.removeListener(_handlePresetSourcesChanged);
  }

  void _handleEditorChanged() {
    final sourceImagePath = controller.session.sourceImagePath;

    if (sourceImagePath != _lastSourceImagePath) {
      _lastSourceImagePath = sourceImagePath;
      _lastObservedActivePresetId = controller.session.activePresetId;
      _activeContextPanel = null;
      _isPrecisionInteractionActive = false;
      _resetPresetSession(autoApply: sourceImagePath != null);
      return;
    }

    final activePresetId = controller.session.activePresetId;
    if (activePresetId == _lastObservedActivePresetId) {
      return;
    }

    _lastObservedActivePresetId = activePresetId;
    _syncActivePresetWithTrail(activePresetId);
  }

  void _syncActivePresetWithTrail(String? presetId) {
    final candidate = _candidateForSessionPresetId(presetId);
    if (candidate == null) {
      return;
    }

    final currentKey =
        _presetTrailIndex >= 0 && _presetTrailIndex < _presetTrail.length
        ? _presetTrail[_presetTrailIndex]
        : null;

    if (currentKey == candidate.key) {
      return;
    }

    final existingIndex = _presetTrail.lastIndexOf(candidate.key);
    if (existingIndex >= 0) {
      _presetTrailIndex = existingIndex;
    } else {
      if (_presetTrailIndex < _presetTrail.length - 1) {
        _presetTrail.removeRange(_presetTrailIndex + 1, _presetTrail.length);
      }
      _presetTrail.add(candidate.key);
      _presetTrailIndex = _presetTrail.length - 1;
    }

    _visitedPresetKeys.add(candidate.key);
    _cyclePresetKeys.add(candidate.key);

    if (mounted) {
      setState(() {});
    }
  }

  void _handlePresetSourcesChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
    _scheduleInitialRandomPreset();
  }

  void _resetPresetSession({required bool autoApply}) {
    _applyGeneration += 1;
    _presetTrail.clear();
    _visitedPresetKeys.clear();
    _cyclePresetKeys.clear();
    _presetTrailIndex = -1;
    _lastObservedActivePresetId = controller.session.activePresetId;
    _pendingInitialRandomPreset = autoApply;
    _isApplyingPreset = false;

    if (mounted) {
      setState(() {});
    }

    _scheduleInitialRandomPreset();
  }

  void _scheduleInitialRandomPreset() {
    if (!_pendingInitialRandomPreset || !controller.session.hasImage) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_ensureInitialRandomPreset());
      }
    });
  }

  Future<void> _ensureInitialRandomPreset() async {
    if (!_pendingInitialRandomPreset ||
        _isApplyingPreset ||
        !controller.session.hasImage) {
      return;
    }

    final candidates = _presetCandidates();
    if (candidates.isEmpty) {
      // Keep this pending. A remote catalog or local library listener will
      // retry as soon as presets become available.
      return;
    }

    _pendingInitialRandomPreset = false;
    await _advanceToRandomPreset();
  }

  List<_MobilePresetCandidate> _presetCandidates() {
    final remoteItems =
        presetRemoteController?.items ?? const <RemotePresetCatalogItem>[];
    final records = presetLibraryController?.records ?? const <PresetRecord>[];
    final candidates = <_MobilePresetCandidate>[];
    final discoverableRemoteKeys = <String>{};

    for (final item in remoteItems) {
      final candidate = _MobilePresetCandidate.remote(item);
      candidates.add(candidate);
      discoverableRemoteKeys.add(candidate.sessionPresetId);
    }

    for (final record in records) {
      final origin = record.origin;

      if (origin.type == PresetOriginType.remoteInstalled) {
        final sourceId = origin.sourceId;
        final remotePresetId = origin.remotePresetId;

        if (sourceId != null && remotePresetId != null) {
          final remoteSessionId = 'remote:$sourceId:$remotePresetId';
          if (discoverableRemoteKeys.contains(remoteSessionId)) {
            continue;
          }
        }
      }

      candidates.add(_MobilePresetCandidate.local(record));
    }

    return List<_MobilePresetCandidate>.unmodifiable(candidates);
  }

  _MobilePresetCandidate? _candidateByKey(String key) {
    for (final candidate in _presetCandidates()) {
      if (candidate.key == key) {
        return candidate;
      }
    }

    return null;
  }

  _MobilePresetCandidate? _activeCandidate() {
    final activePresetId = controller.session.activePresetId;
    if (activePresetId == null) {
      return null;
    }

    for (final candidate in _presetCandidates()) {
      if (candidate.sessionPresetId == activePresetId) {
        return candidate;
      }
    }

    return null;
  }

  _MobilePresetCandidate? _candidateForSessionPresetId(String? presetId) {
    if (presetId == null) {
      return null;
    }

    for (final candidate in _presetCandidates()) {
      if (candidate.sessionPresetId == presetId) {
        return candidate;
      }
    }

    return null;
  }

  Future<void> _handlePresetSwipe(
    EditorViewportSwipeDirection direction,
  ) async {
    if (_isApplyingPreset || !controller.session.hasImage) {
      return;
    }

    switch (direction) {
      case EditorViewportSwipeDirection.left:
        if (_presetTrailIndex < _presetTrail.length - 1) {
          _presetTrailIndex += 1;
          await _applyTrailEntry();
        } else {
          await _advanceToRandomPreset();
        }
        return;
      case EditorViewportSwipeDirection.right:
        if (_presetTrailIndex <= 0) {
          return;
        }

        _presetTrailIndex -= 1;
        await _applyTrailEntry();
        return;
    }
  }

  Future<void> _advanceToRandomPreset() async {
    final candidates = _presetCandidates();
    if (candidates.isEmpty) {
      return;
    }

    var pool = candidates
        .where((candidate) => !_cyclePresetKeys.contains(candidate.key))
        .toList(growable: false);

    // Finish a shuffled/random cycle before allowing repeats. Unique-viewed
    // tracking remains intact across cycles for the current image.
    if (pool.isEmpty) {
      _cyclePresetKeys.clear();
      final activeKey =
          _presetTrailIndex >= 0 && _presetTrailIndex < _presetTrail.length
          ? _presetTrail[_presetTrailIndex]
          : null;
      pool = candidates
          .where(
            (candidate) => candidates.length == 1 || candidate.key != activeKey,
          )
          .toList(growable: false);
    }

    if (pool.isEmpty) {
      return;
    }

    final candidate = pool[_random.nextInt(pool.length)];

    if (_presetTrailIndex < _presetTrail.length - 1) {
      _presetTrail.removeRange(_presetTrailIndex + 1, _presetTrail.length);
    }

    _presetTrail.add(candidate.key);
    _presetTrailIndex = _presetTrail.length - 1;
    _visitedPresetKeys.add(candidate.key);
    _cyclePresetKeys.add(candidate.key);

    if (mounted) {
      setState(() {});
    }

    await _applyCandidate(candidate);
  }

  Future<void> _applyTrailEntry() async {
    if (_presetTrailIndex < 0 || _presetTrailIndex >= _presetTrail.length) {
      return;
    }

    final candidate = _candidateByKey(_presetTrail[_presetTrailIndex]);
    if (candidate == null) {
      return;
    }

    await _applyCandidate(candidate);
  }

  Future<void> _applyCandidate(_MobilePresetCandidate candidate) async {
    final sourceImagePath = controller.session.sourceImagePath;
    if (sourceImagePath == null) {
      return;
    }

    final generation = ++_applyGeneration;

    setState(() {
      _isApplyingPreset = true;
    });

    try {
      final localRecord = candidate.localRecord;
      if (localRecord != null) {
        controller.applyPreset(
          presetId: localRecord.libraryId,
          presetName: localRecord.preset.name,
          adjustments: PresetAdjustmentMapper.toImageAdjustments(
            localRecord.preset.adjustments,
          ),
          toneCurves: PresetAdjustmentMapper.toToneCurves(
            localRecord.preset.toneCurves,
          ),
        );
        return;
      }

      final item = candidate.remoteItem;
      final remote = presetRemoteController;
      final library = presetLibraryController;

      if (item == null || remote == null || library == null) {
        return;
      }

      final saved = library.remoteRecordFor(
        sourceId: item.source.id,
        remotePresetId: item.entry.id,
      );
      final savedRevision = saved?.origin.remoteRevision;
      final preset =
          saved != null &&
              savedRevision != null &&
              savedRevision >= item.entry.revision
          ? saved.preset
          : await _loadRemotePresetWithSavedFallback(
              remote: remote,
              item: item,
              saved: saved,
            );

      if (!mounted ||
          generation != _applyGeneration ||
          controller.session.sourceImagePath != sourceImagePath) {
        return;
      }

      controller.applyPreset(
        presetId: candidate.sessionPresetId,
        presetName: preset.name,
        adjustments: PresetAdjustmentMapper.toImageAdjustments(
          preset.adjustments,
        ),
        toneCurves: PresetAdjustmentMapper.toToneCurves(preset.toneCurves),
      );
    } on Object catch (error) {
      if (mounted) {
        _showMessage('Could not apply filter: $error');
      }
    } finally {
      if (mounted && generation == _applyGeneration) {
        setState(() {
          _isApplyingPreset = false;
        });
      }
    }
  }

  Future<Preset> _loadRemotePresetWithSavedFallback({
    required PresetRemoteController remote,
    required RemotePresetCatalogItem item,
    required PresetRecord? saved,
  }) async {
    try {
      return await remote.presetForUse(item);
    } on Object {
      if (saved != null) {
        return saved.preset;
      }
      rethrow;
    }
  }

  Future<void> _showImageActions() async {
    if (!controller.session.hasImage) {
      return;
    }

    final activeCandidate = _activeCandidate();
    final hasCustomLook = !controller.session.adjustments.isDefault;
    final activeRemoteItem = activeCandidate?.remoteItem;
    final activeLocalRecord = activeCandidate?.localRecord;
    final savedRemote = activeRemoteItem == null
        ? null
        : presetLibraryController?.remoteRecordFor(
            sourceId: activeRemoteItem.source.id,
            remotePresetId: activeRemoteItem.entry.id,
          );
    final remoteIsSaved =
        savedRemote != null &&
        (savedRemote.origin.remoteRevision ?? 0) >=
            activeRemoteItem!.entry.revision;
    final filterAlreadySaved = activeLocalRecord != null || remoteIsSaved;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    activeCandidate?.name ?? 'Current image',
                    style: AppTypography.title,
                  ),
                  subtitle: Text(
                    '${_visitedPresetKeys.length} of '
                    '${_presetCandidates().length} filters viewed',
                    style: AppTypography.bodyMuted,
                  ),
                ),
                ListTile(
                  key: const ValueKey('mobile-image-action-save-image'),
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Save image'),
                  enabled: widget.onExportImage != null && !widget.isExporting,
                  onTap: widget.onExportImage == null || widget.isExporting
                      ? null
                      : () {
                          Navigator.of(sheetContext).pop();
                          unawaited(widget.onExportImage!());
                        },
                ),
                ListTile(
                  key: const ValueKey('mobile-image-action-save-filter'),
                  leading: Icon(
                    filterAlreadySaved ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  title: Text(
                    filterAlreadySaved ? 'Filter saved' : 'Save filter',
                  ),
                  enabled:
                      !filterAlreadySaved &&
                      (activeCandidate != null || hasCustomLook),
                  onTap:
                      filterAlreadySaved ||
                          (activeCandidate == null && !hasCustomLook)
                      ? null
                      : () {
                          Navigator.of(sheetContext).pop();
                          unawaited(_saveActiveFilter(activeCandidate));
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveActiveFilter(_MobilePresetCandidate? candidate) async {
    final library = presetLibraryController;
    if (library == null) {
      return;
    }

    final remoteItem = candidate?.remoteItem;
    final remote = presetRemoteController;

    if (remoteItem != null && remote != null) {
      try {
        await remote.save(remoteItem, libraryController: library);
        if (mounted) {
          setState(() {});
          _showMessage('${remoteItem.entry.name} saved for offline use.');
        }
      } on Object catch (error) {
        if (mounted) {
          _showMessage('Could not save filter: $error');
        }
      }
      return;
    }

    if (candidate?.localRecord != null) {
      _showMessage('This filter is already saved.');
      return;
    }

    await _saveCurrentAdjustmentsAsFilter();
  }

  Future<void> _saveCurrentAdjustmentsAsFilter() async {
    final library = presetLibraryController;
    if (library == null) {
      return;
    }

    final nameController = TextEditingController(text: 'My filter');

    try {
      final name = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Save filter'),
            content: TextField(
              key: const ValueKey('mobile-save-filter-name'),
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
              onSubmitted: (value) {
                final normalized = value.trim();
                if (normalized.isNotEmpty) {
                  Navigator.of(dialogContext).pop(normalized);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final normalized = nameController.text.trim();
                  if (normalized.isNotEmpty) {
                    Navigator.of(dialogContext).pop(normalized);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (!mounted || name == null) {
        return;
      }

      await library.saveCurrent(
        name: name,
        adjustments: controller.session.adjustments,
        toneCurves: controller.session.effectiveToneCurves,
      );

      if (mounted) {
        _showMessage('$name saved.');
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage('Could not save filter: $error');
      }
    } finally {
      nameController.dispose();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleContextPanel(_MobileContextPanel panel) {
    if (controller.isEditTransactionActive) {
      controller.endEditTransaction();
    }

    setState(() {
      _isPrecisionInteractionActive = false;
      _activeContextPanel = _activeContextPanel == panel ? null : panel;
    });
  }

  void _closeContextPanel() {
    if (_activeContextPanel == null) {
      return;
    }

    if (controller.isEditTransactionActive) {
      controller.endEditTransaction();
    }

    setState(() {
      _isPrecisionInteractionActive = false;
      _activeContextPanel = null;
    });
  }

  void _handlePrecisionInteractionChanged(bool active) {
    if (!mounted || _isPrecisionInteractionActive == active) {
      return;
    }

    setState(() {
      _isPrecisionInteractionActive = active;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final mediaQuery = MediaQuery.of(context);
          final safeTop = mediaQuery.padding.top;
          final safeBottom = mediaQuery.padding.bottom;
          final isCompactWidth =
              mediaQuery.size.width < AppDimensions.mobileCompactWidth;
          final isCompactHeight =
              mediaQuery.size.height < AppDimensions.mobileCompactHeight;
          final panelHorizontalInset = isCompactWidth
              ? AppSpacing.xs
              : AppSpacing.sm;
          final chromeHorizontalInset = isCompactWidth
              ? AppSpacing.sm
              : AppSpacing.md;
          final contextualPanelMaxHeight =
              (mediaQuery.size.height * (isCompactHeight ? 0.42 : 0.38))
                  .clamp(220.0, 360.0)
                  .toDouble();
          final bodyTopPadding = _isPrecisionInteractionActive
              ? safeTop + AppSpacing.sm
              : safeTop + AppDimensions.mobileTopChromeHeight + AppSpacing.sm;
          // The bottom dock is floating chrome, so the image workspace is
          // allowed to continue behind it. Reserving the full dock height
          // made portrait photos height-bound and therefore narrower than the
          // device even though horizontal canvas padding was already zero.
          // Keep only safe-area breathing room here so ordinary portrait
          // ratios can use the full device width without cropping.
          final bodyBottomPadding = safeBottom + AppSpacing.sm;
          final activeCandidate = _candidateForSessionPresetId(
            controller.session.activePresetId,
          );

          return ColoredBox(
            color: AppColors.canvas,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Padding(
                    key: const ValueKey('mobile-editor-image-workspace'),
                    padding: EdgeInsets.only(
                      top: bodyTopPadding,
                      bottom: bodyBottomPadding,
                    ),
                    child: MobileEditorCanvas(
                      sourceImagePath: controller.session.sourceImagePath,
                      adjustments: controller.previewAdjustments,
                      toneCurves: controller.previewToneCurves,
                      transform: controller.session.transform,
                      crop: controller.session.crop,
                      onImportImage: widget.onImportImage,
                      isImporting: widget.isImporting,
                      imageOverlay:
                          _activeContextPanel == _MobileContextPanel.guides &&
                              _guideController.hasGuide
                          ? CompositionGuideOverlay(
                              guide: _guideController.guide,
                              emphasize: true,
                              orientation: _guideController.orientation,
                              color: _guideController.color,
                              opacity: _guideController.opacity,
                            )
                          : null,
                      onTap:
                          controller.session.hasImage &&
                              _activeContextPanel == null
                          ? _showImageActions
                          : null,
                      onHorizontalSwipe:
                          controller.session.hasImage &&
                              _activeContextPanel == null
                          ? (direction) {
                              unawaited(_handlePresetSwipe(direction));
                            }
                          : null,
                      topAction: _isPrecisionInteractionActive
                          ? null
                          : BeforeAfterButton(
                              key: const ValueKey('mobile-before-after'),
                              enabled: controller.canCompareBefore,
                              isShowingBefore: controller.isShowingBefore,
                              onPreviewStart: controller.beginBeforePreview,
                              onPreviewEnd: controller.endBeforePreview,
                              compact: true,
                            ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: _isPrecisionInteractionActive,
                    child: AnimatedOpacity(
                      key: const ValueKey('mobile-top-bar-visibility'),
                      duration: const Duration(milliseconds: 160),
                      opacity: _isPrecisionInteractionActive ? 0 : 1,
                      child: _MobileTopBar(
                        controller: controller,
                        compact: isCompactWidth,
                        hasImage: controller.session.hasImage,
                        isExporting: widget.isExporting,
                        onImportImage: widget.onImportImage,
                        onExportImage: widget.onExportImage,
                        onShowHistory: controller.session.hasImage
                            ? () {
                                _showHistorySheet(context);
                              }
                            : null,
                      ),
                    ),
                  ),
                ),
                if (_activeContextPanel == null &&
                    controller.session.hasImage &&
                    (activeCandidate != null || _isApplyingPreset))
                  Positioned(
                    key: const ValueKey('mobile-active-filter-label'),
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom:
                        safeBottom +
                        AppDimensions.mobileBottomChromeHeight +
                        AppSpacing.xs,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            _isApplyingPreset
                                ? 'Applying filter…'
                                : isCompactWidth
                                ? activeCandidate!.name
                                : '${activeCandidate!.name}  ·  '
                                      '${_visitedPresetKeys.length}/'
                                      '${_presetCandidates().length} viewed',
                            style: AppTypography.bodyMuted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: panelHorizontalInset,
                  right: panelHorizontalInset,
                  bottom:
                      safeBottom +
                      AppDimensions.mobileBottomChromeHeight +
                      AppSpacing.sm,
                  child: MobileEditorToolPanel(
                    visible: _activeContextPanel != null,
                    title: switch (_activeContextPanel) {
                      _MobileContextPanel.presets => 'Presets',
                      _MobileContextPanel.adjust => 'Adjust',
                      _MobileContextPanel.guides => 'Guides',
                      null => '',
                    },
                    maxHeight: contextualPanelMaxHeight,
                    immersive: _isPrecisionInteractionActive,
                    onClose: _closeContextPanel,
                    child: switch (_activeContextPanel) {
                      _MobileContextPanel.presets =>
                        presetLibraryController == null
                            ? const SizedBox.shrink()
                            : MobilePresetPanel(
                                libraryController: presetLibraryController!,
                                remoteController: presetRemoteController,
                                editorController: controller,
                              ),
                      _MobileContextPanel.adjust => MobileAdjustmentPanel(
                        controller: controller,
                        onPrecisionInteractionChanged:
                            _handlePrecisionInteractionChanged,
                      ),
                      _MobileContextPanel.guides => MobileGuidesPanel(
                        controller: _guideController,
                      ),
                      null => const SizedBox.shrink(),
                    },
                  ),
                ),
                Positioned(
                  left: chromeHorizontalInset,
                  right: chromeHorizontalInset,
                  bottom: AppSpacing.md,
                  child: IgnorePointer(
                    ignoring: _isPrecisionInteractionActive,
                    child: AnimatedOpacity(
                      key: const ValueKey('mobile-bottom-dock-visibility'),
                      duration: const Duration(milliseconds: 160),
                      opacity: _isPrecisionInteractionActive ? 0 : 1,
                      child: _MobileToolDock(
                        controller: controller,
                        presetLibraryController: presetLibraryController,
                        presetsSelected:
                            _activeContextPanel == _MobileContextPanel.presets,
                        adjustSelected:
                            _activeContextPanel == _MobileContextPanel.adjust,
                        guidesSelected:
                            _activeContextPanel == _MobileContextPanel.guides,
                        onOpenPresets: presetLibraryController == null
                            ? null
                            : () {
                                _toggleContextPanel(
                                  _MobileContextPanel.presets,
                                );
                              },
                        onOpenEdit: controller.session.hasImage
                            ? () {
                                _toggleContextPanel(_MobileContextPanel.adjust);
                              }
                            : null,
                        onOpenCrop: controller.session.hasImage
                            ? () {
                                _closeContextPanel();
                                unawaited(_showCropWorkspace(context));
                              }
                            : null,
                        onOpenGuides: controller.session.hasImage
                            ? () {
                                _toggleContextPanel(_MobileContextPanel.guides);
                              }
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCropWorkspace(BuildContext context) async {
    if (controller.isEditTransactionActive) {
      controller.endEditTransaction();
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) {
          return Scaffold(
            backgroundColor: AppColors.canvas,
            body: CropWorkspace(
              controller: controller,
              compact: true,
              compositionGuideController: _guideController,
              onCancel: () {
                Navigator.of(routeContext).pop();
              },
              onDone: () {
                Navigator.of(routeContext).pop();
              },
            ),
          );
        },
      ),
    );
  }

  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height * 0.55;

        return SafeArea(
          top: false,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('History', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(child: EditorHistoryList(controller: controller)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MobilePresetCandidate {
  const _MobilePresetCandidate._({
    required this.key,
    required this.sessionPresetId,
    required this.name,
    this.remoteItem,
    this.localRecord,
  });

  factory _MobilePresetCandidate.remote(RemotePresetCatalogItem item) {
    final sessionPresetId = 'remote:${item.source.id}:${item.entry.id}';
    return _MobilePresetCandidate._(
      key: sessionPresetId,
      sessionPresetId: sessionPresetId,
      name: item.entry.name,
      remoteItem: item,
    );
  }

  factory _MobilePresetCandidate.local(PresetRecord record) {
    return _MobilePresetCandidate._(
      key: 'library:${record.libraryId}',
      sessionPresetId: record.libraryId,
      name: record.preset.name,
      localRecord: record,
    );
  }

  final String key;
  final String sessionPresetId;
  final String name;
  final RemotePresetCatalogItem? remoteItem;
  final PresetRecord? localRecord;
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    required this.controller,
    required this.compact,
    required this.hasImage,
    required this.isExporting,
    required this.onImportImage,
    this.onExportImage,
    this.onShowHistory,
  });

  final EditorController controller;
  final bool compact;
  final bool hasImage;
  final bool isExporting;
  final Future<void> Function() onImportImage;
  final Future<void> Function()? onExportImage;
  final VoidCallback? onShowHistory;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? AppSpacing.sm : AppSpacing.md,
          AppSpacing.sm,
          compact ? AppSpacing.sm : AppSpacing.md,
          0,
        ),
        child: Row(
          children: [
            if (compact)
              _FloatingIconButton(
                key: const ValueKey('mobile-top-import'),
                icon: Icons.add_photo_alternate_outlined,
                tooltip: hasImage ? 'Change image' : 'Import image',
                enabledStyle: true,
                onPressed: () {
                  unawaited(onImportImage());
                },
              )
            else
              Expanded(
                child: _FloatingActionPill(
                  key: const ValueKey('mobile-top-import'),
                  icon: Icons.add_photo_alternate_outlined,
                  label: hasImage ? 'Change image' : AppConstants.appName,
                  onTap: onImportImage,
                ),
              ),
            SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
            _FloatingIconButton(
              key: const ValueKey('mobile-undo'),
              icon: Icons.undo,
              tooltip: 'Undo',
              onPressed: controller.canUndo ? controller.undo : null,
            ),
            const SizedBox(width: AppSpacing.xs),
            _FloatingIconButton(
              key: const ValueKey('mobile-redo'),
              icon: Icons.redo,
              tooltip: 'Redo',
              onPressed: controller.canRedo ? controller.redo : null,
            ),
            const SizedBox(width: AppSpacing.xs),
            _FloatingIconButton(
              key: const ValueKey('mobile-export'),
              icon: Icons.file_download_outlined,
              tooltip: 'Export',
              isBusy: isExporting,
              onPressed: hasImage && !isExporting && onExportImage != null
                  ? () {
                      unawaited(onExportImage!());
                    }
                  : null,
            ),
            const SizedBox(width: AppSpacing.xs),
            PopupMenuButton<_MobileMenuAction>(
              key: const ValueKey('mobile-top-menu'),
              enabled: hasImage && onShowHistory != null,
              color: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.xl),
                side: const BorderSide(color: AppColors.border),
              ),
              onSelected: (action) {
                switch (action) {
                  case _MobileMenuAction.history:
                    onShowHistory?.call();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _MobileMenuAction.history,
                  child: Row(
                    children: [
                      Icon(Icons.history),
                      SizedBox(width: AppSpacing.sm),
                      Text('History'),
                    ],
                  ),
                ),
              ],
              child: const _FloatingIconButton(
                icon: Icons.more_horiz,
                tooltip: 'More',
                enabledStyle: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileToolDock extends StatelessWidget {
  const _MobileToolDock({
    required this.controller,
    required this.presetsSelected,
    required this.adjustSelected,
    required this.guidesSelected,
    this.presetLibraryController,
    this.onOpenPresets,
    this.onOpenEdit,
    this.onOpenCrop,
    this.onOpenGuides,
  });

  final EditorController controller;
  final bool presetsSelected;
  final bool adjustSelected;
  final bool guidesSelected;
  final PresetLibraryController? presetLibraryController;
  final VoidCallback? onOpenPresets;
  final VoidCallback? onOpenEdit;
  final VoidCallback? onOpenCrop;
  final VoidCallback? onOpenGuides;

  @override
  Widget build(BuildContext context) {
    final hasImage = controller.session.hasImage;

    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('mobile-bottom-dock'),
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadii.editorDock),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _DockButton(
                key: const ValueKey('mobile-tool-presets'),
                icon: Icons.auto_awesome_outlined,
                label: 'Presets',
                enabled: hasImage && presetLibraryController != null,
                selected: presetsSelected,
                onTap: onOpenPresets,
              ),
            ),
            Expanded(
              child: _DockButton(
                key: const ValueKey('mobile-tool-adjust'),
                icon: Icons.tune,
                label: 'Adjust',
                enabled: hasImage,
                selected: adjustSelected,
                onTap: onOpenEdit,
              ),
            ),
            Expanded(
              child: _DockButton(
                key: const ValueKey('mobile-tool-crop'),
                icon: Icons.crop,
                label: 'Crop',
                enabled: hasImage,
                onTap: onOpenCrop,
              ),
            ),
            Expanded(
              child: _DockButton(
                key: const ValueKey('mobile-tool-guides'),
                icon: Icons.grid_4x4_rounded,
                label: 'Guides',
                enabled: hasImage,
                selected: guidesSelected,
                onTap: onOpenGuides,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingActionPill extends StatelessWidget {
  const _FloatingActionPill({
    required this.icon,
    required this.label,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: AppDimensions.mobileTouchTarget,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppDimensions.iconMd,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingIconButton extends StatelessWidget {
  const _FloatingIconButton({
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.isBusy = false,
    this.enabledStyle = false,
    super.key,
  });

  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool isBusy;
  final bool enabledStyle;

  @override
  Widget build(BuildContext context) {
    final enabled = enabledStyle || onPressed != null;
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: AppDimensions.mobileTouchTarget,
            height: AppDimensions.mobileTouchTarget,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: isBusy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      icon,
                      size: AppDimensions.iconMd,
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.accentMuted : Colors.transparent;
    final color = selected
        ? AppColors.accent
        : enabled
        ? AppColors.textSecondary
        : AppColors.textDisabled;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.mobileTouchTarget,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxs,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: AppDimensions.iconMd, color: color),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
