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
import '../../domain/adjustment_definition.dart';
import '../../domain/adjustment_type.dart';
import 'adjustment_control.dart';
import 'before_after_button.dart';
import 'crop_workspace.dart';
import 'editor_history_list.dart';
import 'editor_image_viewport.dart';
import 'mobile_editor_canvas.dart';
import 'mobile_editor_tool_panel.dart';

enum _MobileMenuAction { history }

enum _MobileContextPanel { presets }

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
  final List<String> _presetTrail = <String>[];
  final Set<String> _visitedPresetKeys = <String>{};
  final Set<String> _cyclePresetKeys = <String>{};

  String? _lastSourceImagePath;
  String? _lastObservedActivePresetId;
  int _presetTrailIndex = -1;
  int _applyGeneration = 0;
  bool _pendingInitialRandomPreset = false;
  bool _isApplyingPreset = false;
  _MobileContextPanel? _activeContextPanel;

  EditorController get controller => widget.controller;
  PresetLibraryController? get presetLibraryController =>
      widget.presetLibraryController;
  PresetRemoteController? get presetRemoteController =>
      widget.presetRemoteController;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
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

  void _togglePresetsPanel() {
    setState(() {
      _activeContextPanel = _activeContextPanel == _MobileContextPanel.presets
          ? null
          : _MobileContextPanel.presets;
    });
  }

  void _closeContextPanel() {
    if (_activeContextPanel == null) {
      return;
    }

    setState(() {
      _activeContextPanel = null;
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
          const topChromeHeight = 56.0;
          const bottomChromeHeight = 84.0;
          final contextualPanelMaxHeight = (mediaQuery.size.height * 0.38)
              .clamp(240.0, 360.0)
              .toDouble();
          final bodyTopPadding = safeTop + topChromeHeight + AppSpacing.sm;
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
                      transform: controller.session.transform,
                      crop: controller.session.crop,
                      onImportImage: widget.onImportImage,
                      isImporting: widget.isImporting,
                      onTap: controller.session.hasImage
                          ? _showImageActions
                          : null,
                      onHorizontalSwipe: controller.session.hasImage
                          ? (direction) {
                              unawaited(_handlePresetSwipe(direction));
                            }
                          : null,
                      topAction: BeforeAfterButton(
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
                  child: _MobileTopBar(
                    controller: controller,
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
                if (_activeContextPanel == null &&
                    controller.session.hasImage &&
                    (activeCandidate != null || _isApplyingPreset))
                  Positioned(
                    key: const ValueKey('mobile-active-filter-label'),
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: safeBottom + bottomChromeHeight + AppSpacing.xs,
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
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  bottom: safeBottom + bottomChromeHeight + AppSpacing.sm,
                  child: MobileEditorToolPanel(
                    visible:
                        _activeContextPanel == _MobileContextPanel.presets &&
                        presetLibraryController != null,
                    title: 'Presets',
                    maxHeight: contextualPanelMaxHeight,
                    onClose: _closeContextPanel,
                    child:
                        _activeContextPanel == _MobileContextPanel.presets &&
                            presetLibraryController != null
                        ? MobilePresetPanel(
                            libraryController: presetLibraryController!,
                            remoteController: presetRemoteController,
                            editorController: controller,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: _MobileToolDock(
                    controller: controller,
                    presetLibraryController: presetLibraryController,
                    presetsSelected:
                        _activeContextPanel == _MobileContextPanel.presets,
                    onOpenPresets: presetLibraryController == null
                        ? null
                        : _togglePresetsPanel,
                    onOpenEdit: controller.session.hasImage
                        ? () {
                            _closeContextPanel();
                            _showEditSheet(context);
                          }
                        : null,
                    onOpenCrop: controller.session.hasImage
                        ? () {
                            _closeContextPanel();
                            unawaited(_showCropWorkspace(context));
                          }
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    final exposureDefinition = AdjustmentDefinitions.of(
      AdjustmentType.exposure,
    );

    final contrastDefinition = AdjustmentDefinitions.of(
      AdjustmentType.contrast,
    );

    final highlightsDefinition = AdjustmentDefinitions.of(
      AdjustmentType.highlights,
    );

    final shadowsDefinition = AdjustmentDefinitions.of(AdjustmentType.shadows);

    final whitesDefinition = AdjustmentDefinitions.of(AdjustmentType.whites);

    final blacksDefinition = AdjustmentDefinitions.of(AdjustmentType.blacks);

    final temperatureDefinition = AdjustmentDefinitions.of(
      AdjustmentType.temperature,
    );

    final tintDefinition = AdjustmentDefinitions.of(AdjustmentType.tint);

    final vibranceDefinition = AdjustmentDefinitions.of(
      AdjustmentType.vibrance,
    );

    final saturationDefinition = AdjustmentDefinitions.of(
      AdjustmentType.saturation,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      showDragHandle: false,
      isScrollControlled: true,
      builder: (context) {
        AdjustmentType? activeAdjustment;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

            final availableHeight = MediaQuery.sizeOf(context).height;

            final isFocused = activeAdjustment != null;

            void focusAdjustment(AdjustmentType type) {
              if (activeAdjustment == type) {
                return;
              }

              if (!controller.isEditTransactionActive) {
                controller.beginEditTransaction();
              }

              setSheetState(() {
                activeAdjustment = type;
              });
            }

            void leaveFocusedMode() {
              if (activeAdjustment == null) {
                return;
              }

              if (controller.isEditTransactionActive) {
                controller.endEditTransaction();
              }

              setSheetState(() {
                activeAdjustment = null;
              });
            }

            return SizedBox(
              height: availableHeight * 0.68,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  IgnorePointer(
                    ignoring: isFocused,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      opacity: isFocused ? 0.0 : 1.0,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          key: const ValueKey('mobile-edit-sheet-surface'),
                          constraints: BoxConstraints(
                            maxHeight: availableHeight * 0.68,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppRadii.md),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: SingleChildScrollView(
                              key: const ValueKey('mobile-edit-scroll'),
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.sm,
                                AppSpacing.md,
                                AppSpacing.lg + bottomInset,
                              ),
                              child: AnimatedBuilder(
                                animation: controller,
                                builder: (context, _) {
                                  final session = controller.session;

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 36,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: AppColors.borderStrong,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Row(
                                        children: [
                                          const Expanded(
                                            child: Text(
                                              'Edit',
                                              style: AppTypography.title,
                                            ),
                                          ),
                                          TextButton(
                                            key: const ValueKey(
                                              'mobile-reset-adjustments',
                                            ),
                                            onPressed:
                                                controller.canResetAdjustments
                                                ? controller.resetAdjustments
                                                : null,
                                            child: const Text('Reset'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      const Text(
                                        'Light',
                                        style: AppTypography.label,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      AdjustmentControl(
                                        definition: exposureDefinition,
                                        value: session.adjustments.exposure,
                                        onChanged: (value) {
                                          controller.updateAdjustment(
                                            AdjustmentType.exposure,
                                            value,
                                          );
                                        },
                                        onInteractionStart: () {
                                          focusAdjustment(
                                            AdjustmentType.exposure,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      AdjustmentControl(
                                        definition: contrastDefinition,
                                        value: session.adjustments.contrast,
                                        onChanged: (value) {
                                          controller.updateAdjustment(
                                            AdjustmentType.contrast,
                                            value,
                                          );
                                        },
                                        onInteractionStart: () {
                                          focusAdjustment(
                                            AdjustmentType.contrast,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      AdjustmentControl(
                                        definition: highlightsDefinition,
                                        value: session.adjustments.highlights,
                                        onChanged: (value) {
                                          controller.updateAdjustment(
                                            AdjustmentType.highlights,
                                            value,
                                          );
                                        },
                                        onInteractionStart: () {
                                          focusAdjustment(
                                            AdjustmentType.highlights,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      AdjustmentControl(
                                        definition: shadowsDefinition,
                                        value: session.adjustments.shadows,
                                        onChanged: (value) {
                                          controller.updateAdjustment(
                                            AdjustmentType.shadows,
                                            value,
                                          );
                                        },
                                        onInteractionStart: () {
                                          focusAdjustment(
                                            AdjustmentType.shadows,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      AdjustmentControl(
                                        definition: whitesDefinition,
                                        value: session.adjustments.whites,
                                        onChanged: (value) {
                                          controller.updateAdjustment(
                                            AdjustmentType.whites,
                                            value,
                                          );
                                        },
                                        onInteractionStart: () {
                                          focusAdjustment(
                                            AdjustmentType.whites,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      AdjustmentControl(
                                        definition: blacksDefinition,
                                        value: session.adjustments.blacks,
                                        onChanged: (value) {
                                          controller.updateAdjustment(
                                            AdjustmentType.blacks,
                                            value,
                                          );
                                        },
                                        onInteractionStart: () {
                                          focusAdjustment(
                                            AdjustmentType.blacks,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      const Divider(height: 1),
                                      const SizedBox(height: AppSpacing.lg),
                                      const Text(
                                        'Color',
                                        style: AppTypography.label,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      AdjustmentControl(
                                        definition: temperatureDefinition,
                                        value: session.adjustments.temperature,
                                        onChanged: (value) {
                                          controller.updateAdjustment(
                                            AdjustmentType.temperature,
                                            value,
                                          );
                                        },
                                        onInteractionStart: () {
                                          focusAdjustment(
                                            AdjustmentType.temperature,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      AdjustmentControl(
                                        definition: tintDefinition,
                                        value: session.adjustments.tint,
                                        onChanged: (value) {
                                          controller.updateAdjustment(
                                            AdjustmentType.tint,
                                            value,
                                          );
                                        },
                                        onInteractionStart: () {
                                          focusAdjustment(AdjustmentType.tint);
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      AdjustmentControl(
                                        definition: vibranceDefinition,
                                        value: session.adjustments.vibrance,
                                        onChanged: (value) {
                                          controller.updateAdjustment(
                                            AdjustmentType.vibrance,
                                            value,
                                          );
                                        },
                                        onInteractionStart: () {
                                          focusAdjustment(
                                            AdjustmentType.vibrance,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      AdjustmentControl(
                                        definition: saturationDefinition,
                                        value: session.adjustments.saturation,
                                        onChanged: (value) {
                                          controller.updateAdjustment(
                                            AdjustmentType.saturation,
                                            value,
                                          );
                                        },
                                        onInteractionStart: () {
                                          focusAdjustment(
                                            AdjustmentType.saturation,
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isFocused)
                    AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        final type = activeAdjustment!;

                        final definition = AdjustmentDefinitions.of(type);

                        final value = controller.session.adjustments.valueFor(
                          type,
                        );

                        return _MobileFocusedAdjustmentBar(
                          definition: definition,
                          value: value,
                          onChanged: (nextValue) {
                            controller.updateAdjustment(type, nextValue);
                          },
                          onClose: leaveFocusedMode,
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (controller.isEditTransactionActive) {
        controller.endEditTransaction();
      }
    });
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

class _MobileFocusedAdjustmentBar extends StatelessWidget {
  const _MobileFocusedAdjustmentBar({
    required this.definition,
    required this.value,
    required this.onChanged,
    required this.onClose,
  });

  final AdjustmentDefinition definition;
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final sanitizedValue = definition.sanitize(value);

    final divisions =
        ((definition.maxValue - definition.minValue) /
                definition.interactionStep)
            .round();

    return Container(
      key: const ValueKey('mobile-focused-adjustment-bar'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 32,
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        definition.label,
                        textAlign: TextAlign.center,
                        style: AppTypography.label,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: IconButton(
                        key: const ValueKey('mobile-focused-close'),
                        onPressed: onClose,
                        tooltip: 'Back to adjustments',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatValue(definition, sanitizedValue),
                key: const ValueKey('mobile-focused-value'),
                style: AppTypography.title,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      key: const ValueKey('mobile-focused-decrement'),
                      onPressed: sanitizedValue <= definition.minValue
                          ? null
                          : () {
                              onChanged(
                                definition.sanitize(
                                  sanitizedValue - definition.interactionStep,
                                ),
                              );
                            },
                      tooltip: 'Decrease ${definition.label}',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      key: const ValueKey('mobile-focused-slider'),
                      value: sanitizedValue,
                      min: definition.minValue,
                      max: definition.maxValue,
                      divisions: divisions,
                      onChanged: (nextValue) {
                        onChanged(definition.sanitize(nextValue));
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      key: const ValueKey('mobile-focused-increment'),
                      onPressed: sanitizedValue >= definition.maxValue
                          ? null
                          : () {
                              onChanged(
                                definition.sanitize(
                                  sanitizedValue + definition.interactionStep,
                                ),
                              );
                            },
                      tooltip: 'Increase ${definition.label}',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatValue(AdjustmentDefinition definition, double value) {
    final decimalPlaces = _decimalPlaces(definition.precisionStep);

    final formatted = value.toStringAsFixed(decimalPlaces);

    return value > 0 ? '+$formatted' : formatted;
  }

  static int _decimalPlaces(double value) {
    if (value == value.roundToDouble()) {
      return 0;
    }

    final text = value.toString();

    if (!text.contains('.')) {
      return 0;
    }

    return text.split('.').last.length;
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    required this.controller,
    required this.hasImage,
    required this.isExporting,
    required this.onImportImage,
    this.onExportImage,
    this.onShowHistory,
  });

  final EditorController controller;
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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        child: Row(
          children: [
            Expanded(
              child: _FloatingActionPill(
                key: const ValueKey('mobile-top-import'),
                icon: Icons.add_photo_alternate_outlined,
                label: hasImage ? 'Change image' : AppConstants.appName,
                onTap: onImportImage,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
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
    this.presetLibraryController,
    this.onOpenPresets,
    this.onOpenEdit,
    this.onOpenCrop,
  });

  final EditorController controller;
  final bool presetsSelected;
  final PresetLibraryController? presetLibraryController;
  final VoidCallback? onOpenPresets;
  final VoidCallback? onOpenEdit;
  final VoidCallback? onOpenCrop;

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
          borderRadius: BorderRadius.circular(28),
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
            const Expanded(
              child: _DockButton(
                key: ValueKey('mobile-tool-guides'),
                icon: Icons.grid_4x4_rounded,
                label: 'Guides',
                enabled: false,
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
          height: 44,
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
            width: 44,
            height: 44,
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
    final background = selected
        ? AppColors.accentMuted
        : enabled
        ? AppColors.surfaceElevated
        : Colors.transparent;
    final color = selected
        ? AppColors.accent
        : enabled
        ? AppColors.textPrimary
        : AppColors.textDisabled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
    );
  }
}
