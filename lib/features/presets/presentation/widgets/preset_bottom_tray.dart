import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_radii.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../../editor/application/editor_controller.dart';
import '../../../editor/presentation/widgets/editor_crop_preview.dart';
import '../../application/preset_adjustment_mapper.dart';
import '../../application/preset_file_gateway.dart';
import '../../application/preset_library_controller.dart';
import '../../application/preset_remote_controller.dart';
import '../../domain/preset.dart';
import '../../domain/preset_json_codec.dart';
import '../../domain/preset_record.dart';
import '../../infrastructure/local_preset_file_gateway.dart';
import 'preset_library_view.dart';

class PresetBottomTray extends StatelessWidget {
  const PresetBottomTray({
    required this.libraryController,
    required this.editorController,
    this.remoteController,
    this.fileGateway = const LocalPresetFileGateway(),
    super.key,
  });

  final PresetLibraryController libraryController;
  final EditorController editorController;
  final PresetRemoteController? remoteController;
  final PresetFileGateway fileGateway;

  @override
  Widget build(BuildContext context) {
    final remote = remoteController;

    Widget buildLocal() {
      return AnimatedBuilder(
        animation: libraryController,
        builder: (context, _) {
          return AnimatedBuilder(
            animation: editorController,
            builder: (context, _) => _buildContent(context),
          );
        },
      );
    }

    if (remote == null) {
      return buildLocal();
    }

    return AnimatedBuilder(
      animation: remote,
      builder: (context, _) => buildLocal(),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActions(context),
        const SizedBox(height: AppSpacing.sm),
        Expanded(child: _buildStrip(context)),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final remote = remoteController;
    final hasImage = editorController.session.hasImage;

    return Row(
      children: [
        OutlinedButton.icon(
          key: const ValueKey('preset-tray-save-current'),
          onPressed: hasImage && libraryController.isReady
              ? () => _saveCurrent(context)
              : null,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Save current'),
        ),
        const SizedBox(width: AppSpacing.xs),
        IconButton.outlined(
          key: const ValueKey('preset-tray-import'),
          tooltip: 'Import preset',
          onPressed: libraryController.isReady
              ? () => _importPreset(context)
              : null,
          icon: const Icon(Icons.file_open_outlined, size: 18),
        ),
        const Spacer(),
        if (remote != null)
          IconButton(
            key: const ValueKey('preset-tray-refresh'),
            tooltip: 'Refresh remote presets',
            onPressed: remote.isInitialized && !remote.isRefreshing
                ? () => remote.refresh()
                : null,
            icon: remote.isRefreshing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 19),
          ),
      ],
    );
  }

  Widget _buildStrip(BuildContext context) {
    if (libraryController.isLoading) {
      return const Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final libraryError = libraryController.errorMessage;
    if (!libraryController.isReady && libraryError != null) {
      return Center(
        child: TextButton.icon(
          key: const ValueKey('preset-tray-library-retry'),
          onPressed: libraryController.retryInitialize,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry preset library'),
        ),
      );
    }

    final remote = remoteController;
    final remoteItems = remote?.items ?? const <RemotePresetCatalogItem>[];
    final localRecords = _visibleLocalRecords(remoteItems);

    if (localRecords.isEmpty && remoteItems.isEmpty) {
      if (remote != null && remote.isInitializing) {
        return const Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      final remoteUnavailable =
          remote != null &&
          (remote.errorMessage != null || remote.sourceErrors.isNotEmpty);

      return Center(
        child: Text(
          remoteUnavailable
              ? 'Remote presets are unavailable. Saved presets still work offline.'
              : 'No presets available yet.',
          style: AppTypography.bodyMuted,
        ),
      );
    }

    return _ScrollablePresetStrip(
      children: [
        if (localRecords.isNotEmpty) ...[
          _TraySectionMarker(label: 'Saved', count: localRecords.length),
          const SizedBox(width: AppSpacing.xs),
          for (final record in localRecords) ...[
            _LocalPresetCard(
              record: record,
              editorController: editorController,
              onApply: () => _applyLocalPreset(record),
              onExport: () => _exportPreset(context, record),
              onRename: record.origin.isMutable
                  ? () => _renamePreset(context, record)
                  : null,
              onDelete: record.origin.type != PresetOriginType.builtIn
                  ? () => _deletePreset(context, record)
                  : null,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          if (remoteItems.isNotEmpty) ...[
            const VerticalDivider(width: AppSpacing.lg),
          ],
        ],
        if (remoteItems.isNotEmpty) ...[
          _TraySectionMarker(label: 'Discover', count: remoteItems.length),
          const SizedBox(width: AppSpacing.xs),
          for (final item in remoteItems) ...[
            _RemotePresetCard(
              item: item,
              editorController: editorController,
              remoteController: remote!,
              savedRecord: libraryController.remoteRecordFor(
                sourceId: item.source.id,
                remotePresetId: item.entry.id,
              ),
              onApply: () => _applyRemotePreset(context, item),
              onSave: () => _saveRemotePreset(context, item),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ],
    );
  }

  List<PresetRecord> _visibleLocalRecords(
    List<RemotePresetCatalogItem> remoteItems,
  ) {
    return libraryController.records
        .where((record) {
          if (record.origin.type != PresetOriginType.remoteInstalled) {
            return true;
          }

          final sourceId = record.origin.sourceId;
          final remotePresetId = record.origin.remotePresetId;
          if (sourceId == null || remotePresetId == null) {
            return true;
          }

          final stillDiscoverable = remoteItems.any(
            (item) =>
                item.source.id == sourceId && item.entry.id == remotePresetId,
          );

          return !stillDiscoverable;
        })
        .toList(growable: false);
  }

  void _applyLocalPreset(PresetRecord record) {
    if (!editorController.session.hasImage) {
      return;
    }

    editorController.applyPreset(
      presetId: record.libraryId,
      presetName: record.preset.name,
      adjustments: PresetAdjustmentMapper.toImageAdjustments(
        record.preset.adjustments,
      ),
      toneCurves: PresetAdjustmentMapper.toToneCurves(record.preset.toneCurves),
      hslColorMixer: PresetAdjustmentMapper.toHslColorMixer(
        record.preset.hslColorMixer,
      ),
    );
  }

  Future<void> _applyRemotePreset(
    BuildContext context,
    RemotePresetCatalogItem item,
  ) async {
    final remote = remoteController;
    if (remote == null || !editorController.session.hasImage) {
      return;
    }

    try {
      final saved = libraryController.remoteRecordFor(
        sourceId: item.source.id,
        remotePresetId: item.entry.id,
      );
      final savedRevision = saved?.origin.remoteRevision;
      Preset preset;

      if (saved != null &&
          savedRevision != null &&
          savedRevision >= item.entry.revision) {
        preset = saved.preset;
      } else {
        try {
          preset = await remote.presetForUse(item);
        } on Object {
          if (saved == null) {
            rethrow;
          }
          preset = saved.preset;
        }
      }

      if (!context.mounted) {
        return;
      }

      editorController.applyPreset(
        presetId: _remoteSessionPresetId(item),
        presetName: preset.name,
        adjustments: PresetAdjustmentMapper.toImageAdjustments(
          preset.adjustments,
        ),
        toneCurves: PresetAdjustmentMapper.toToneCurves(preset.toneCurves),
        hslColorMixer: PresetAdjustmentMapper.toHslColorMixer(
          preset.hslColorMixer,
        ),
      );
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not apply preset: $error');
      }
    }
  }

  Future<void> _saveRemotePreset(
    BuildContext context,
    RemotePresetCatalogItem item,
  ) async {
    final remote = remoteController;
    if (remote == null || remote.isSaving(item)) {
      return;
    }

    try {
      final record = await remote.save(
        item,
        libraryController: libraryController,
      );

      if (context.mounted) {
        _showMessage(context, 'Saved ${record.preset.name} for offline use.');
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not save preset: $error');
      }
    }
  }

  Future<void> _saveCurrent(BuildContext context) async {
    final draft = await showPresetSaveDialog(context);

    if (draft == null || !context.mounted) {
      return;
    }

    try {
      await libraryController.saveCurrent(
        name: draft.name,
        description: draft.description,
        adjustments: editorController.session.adjustments,
        toneCurves: editorController.session.effectiveToneCurves,
        hslColorMixer: editorController.session.hslColorMixer,
      );

      if (context.mounted) {
        _showMessage(context, 'Preset saved.');
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not save preset: $error');
      }
    }
  }

  Future<void> _importPreset(BuildContext context) async {
    try {
      final preset = await fileGateway.importPreset();
      if (preset == null || !context.mounted) {
        return;
      }

      final existing = libraryController.localRecordForPresetId(preset.id);
      var asCopy = false;

      if (existing != null) {
        final resolution = await showPresetImportConflictDialog(
          context,
          incomingName: preset.name,
          existingName: existing.preset.name,
        );

        if (resolution == null || !context.mounted) {
          return;
        }

        asCopy = resolution == PresetImportConflictResolution.importCopy;
      }

      final record = await libraryController.importPortablePreset(
        preset,
        asCopy: asCopy,
      );

      if (!context.mounted) {
        return;
      }

      if (existing != null && !asCopy) {
        _showMessage(context, 'Replaced ${record.preset.name}.');
      } else if (asCopy) {
        _showMessage(context, 'Imported ${record.preset.name} as a copy.');
      } else {
        _showMessage(context, 'Imported ${record.preset.name}.');
      }
    } on PresetFormatException catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not import preset: ${error.message}');
      }
    } on PresetFileException catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not import preset: ${error.message}');
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not import preset: $error');
      }
    }
  }

  Future<void> _exportPreset(BuildContext context, PresetRecord record) async {
    try {
      final destination = await fileGateway.exportPreset(record.preset);
      if (destination == null || !context.mounted) {
        return;
      }

      _showMessage(context, 'Exported ${record.preset.name}.');
    } on PresetFileException catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not export preset: ${error.message}');
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not export preset: $error');
      }
    }
  }

  Future<void> _renamePreset(BuildContext context, PresetRecord record) async {
    final name = await showPresetRenameDialog(
      context,
      initialName: record.preset.name,
    );

    if (name == null || !context.mounted) {
      return;
    }

    try {
      await libraryController.renameLocal(record.libraryId, name);
      if (context.mounted) {
        _showMessage(context, 'Preset renamed.');
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not rename preset: $error');
      }
    }
  }

  Future<void> _deletePreset(BuildContext context, PresetRecord record) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete preset?'),
          content: Text(
            'Delete “${record.preset.name}” from this device? '
            'Existing image edits will not change.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('preset-tray-delete-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    try {
      await libraryController.delete(record.libraryId);
      if (context.mounted) {
        _showMessage(context, 'Preset deleted.');
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not delete preset: $error');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ScrollablePresetStrip extends StatefulWidget {
  const _ScrollablePresetStrip({required this.children});

  final List<Widget> children;

  @override
  State<_ScrollablePresetStrip> createState() => _ScrollablePresetStripState();
}

class _ScrollablePresetStripState extends State<_ScrollablePresetStrip> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scrollController.hasClients) {
      return;
    }

    // Desktop mouse wheels normally report vertical deltas. Translate those
    // into horizontal motion for the preset strip, while leaving native
    // horizontal trackpad/wheel input to the Scrollable itself.
    final delta = event.scrollDelta.dy;
    if (delta == 0 || event.scrollDelta.dx.abs() > delta.abs()) {
      return;
    }

    final position = _scrollController.position;
    final target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();

    if (target != position.pixels) {
      _scrollController.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _PresetTrayScrollBehavior(),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerSignal: _handlePointerSignal,
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          interactive: true,
          child: ListView(
            key: const ValueKey('preset-bottom-tray-list'),
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            children: widget.children,
          ),
        ),
      ),
    );
  }
}

class _PresetTrayScrollBehavior extends MaterialScrollBehavior {
  const _PresetTrayScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}

class _TraySectionMarker extends StatelessWidget {
  const _TraySectionMarker({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label),
          const SizedBox(height: AppSpacing.xxs),
          Text('$count', style: AppTypography.bodyMuted),
        ],
      ),
    );
  }
}

class _LocalPresetCard extends StatelessWidget {
  const _LocalPresetCard({
    required this.record,
    required this.editorController,
    required this.onApply,
    required this.onExport,
    required this.onRename,
    required this.onDelete,
  });

  final PresetRecord record;
  final EditorController editorController;
  final VoidCallback onApply;
  final VoidCallback onExport;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final sourceImagePath = editorController.session.sourceImagePath;
    final active = editorController.session.activePresetId == record.libraryId;

    return SizedBox(
      width: 152,
      child: Material(
        color: active ? AppColors.accentMuted : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          key: ValueKey('preset-tray-local-${record.libraryId}'),
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: editorController.session.hasImage ? onApply : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LocalPresetPreview(
                    sourceImagePath: sourceImagePath,
                    editorController: editorController,
                    preset: record.preset,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.preset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body,
                      ),
                    ),
                    if (active)
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.accent,
                      ),
                    PopupMenuButton<_TrayPresetMenuAction>(
                      key: ValueKey('preset-tray-menu-${record.libraryId}'),
                      tooltip: 'Preset options',
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      onSelected: (action) {
                        switch (action) {
                          case _TrayPresetMenuAction.export:
                            onExport();
                          case _TrayPresetMenuAction.rename:
                            onRename?.call();
                          case _TrayPresetMenuAction.delete:
                            onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: _TrayPresetMenuAction.export,
                          child: Text('Export'),
                        ),
                        if (onRename != null)
                          const PopupMenuItem(
                            value: _TrayPresetMenuAction.rename,
                            child: Text('Rename'),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: _TrayPresetMenuAction.delete,
                            child: Text('Delete'),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RemotePresetCard extends StatelessWidget {
  const _RemotePresetCard({
    required this.item,
    required this.editorController,
    required this.remoteController,
    required this.savedRecord,
    required this.onApply,
    required this.onSave,
  });

  final RemotePresetCatalogItem item;
  final EditorController editorController;
  final PresetRemoteController remoteController;
  final PresetRecord? savedRecord;
  final VoidCallback onApply;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final savedRevision = savedRecord?.origin.remoteRevision;
    final savedCurrent =
        savedRevision != null && savedRevision >= item.entry.revision;
    final updateAvailable =
        savedRevision != null && savedRevision < item.entry.revision;
    final saving = remoteController.isSaving(item);
    final active =
        editorController.session.activePresetId == _remoteSessionPresetId(item);
    final sourceImagePath = editorController.session.sourceImagePath;

    return SizedBox(
      width: 160,
      child: Material(
        color: active ? AppColors.accentMuted : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          key: ValueKey(
            'preset-tray-remote-${item.source.id}-${item.entry.id}',
          ),
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: editorController.session.hasImage ? onApply : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _RemoteTrayPreview(
                    item: item,
                    editorController: editorController,
                    remoteController: remoteController,
                    savedPreset: savedRecord?.preset,
                    sourceImagePath: sourceImagePath,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.entry.author ?? item.source.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label,
                      ),
                    ),
                    if (active)
                      const Padding(
                        padding: EdgeInsets.only(right: AppSpacing.xxs),
                        child: Icon(
                          Icons.check_circle,
                          size: 15,
                          color: AppColors.accent,
                        ),
                      ),
                    IconButton(
                      key: ValueKey(
                        'preset-tray-save-${item.source.id}-${item.entry.id}',
                      ),
                      tooltip: savedCurrent
                          ? 'Saved for offline use'
                          : updateAvailable
                          ? 'Save latest revision'
                          : 'Save preset',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: savedCurrent || saving ? null : onSave,
                      icon: saving
                          ? const SizedBox.square(
                              dimension: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              savedCurrent
                                  ? Icons.bookmark
                                  : updateAvailable
                                  ? Icons.download_outlined
                                  : Icons.bookmark_border,
                              size: 18,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalPresetPreview extends StatelessWidget {
  const _LocalPresetPreview({
    required this.sourceImagePath,
    required this.editorController,
    required this.preset,
  });

  final String? sourceImagePath;
  final EditorController editorController;
  final Preset preset;

  @override
  Widget build(BuildContext context) {
    final path = sourceImagePath;
    if (path == null) {
      return _previewFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: ColoredBox(
        color: AppColors.canvas,
        child: EditorCropPreview(
          sourceImagePath: path,
          adjustments: PresetAdjustmentMapper.toImageAdjustments(
            preset.adjustments,
          ),
          toneCurves: PresetAdjustmentMapper.toToneCurves(preset.toneCurves),
          hslColorMixer: PresetAdjustmentMapper.toHslColorMixer(
            preset.hslColorMixer,
          ),
          transform: editorController.session.transform,
          crop: editorController.session.crop,
          filterQuality: FilterQuality.low,
          errorBuilder: (_, _, _) => _previewFallback(),
        ),
      ),
    );
  }
}

class _RemoteTrayPreview extends StatelessWidget {
  const _RemoteTrayPreview({
    required this.item,
    required this.editorController,
    required this.remoteController,
    required this.savedPreset,
    required this.sourceImagePath,
  });

  final RemotePresetCatalogItem item;
  final EditorController editorController;
  final PresetRemoteController remoteController;
  final Preset? savedPreset;
  final String? sourceImagePath;

  @override
  Widget build(BuildContext context) {
    final livePreviewFuture = sourceImagePath == null
        ? Future<Preset?>.value(null)
        : savedPreset != null && savedPreset!.revision >= item.entry.revision
        ? Future<Preset?>.value(savedPreset)
        : remoteController.presetForPreview(item);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: FutureBuilder<Preset?>(
        future: livePreviewFuture,
        builder: (context, presetSnapshot) {
          final preset = presetSnapshot.data;
          final path = sourceImagePath;

          if (path != null && preset != null) {
            return ColoredBox(
              color: AppColors.canvas,
              child: EditorCropPreview(
                sourceImagePath: path,
                adjustments: PresetAdjustmentMapper.toImageAdjustments(
                  preset.adjustments,
                ),
                transform: editorController.session.transform,
                crop: editorController.session.crop,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, _, _) => _previewFallback(),
              ),
            );
          }

          return _RemoteAssetPreview(
            future: remoteController.previewFor(item),
            showLoading:
                path != null &&
                presetSnapshot.connectionState == ConnectionState.waiting,
          );
        },
      ),
    );
  }
}

class _RemoteAssetPreview extends StatelessWidget {
  const _RemoteAssetPreview({required this.future, required this.showLoading});

  final Future<Uint8List?> future;
  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snapshot) {
        final bytes = snapshot.data;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (bytes != null && bytes.isNotEmpty)
              Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => _previewFallback(),
              )
            else
              _previewFallback(),
            if (showLoading ||
                snapshot.connectionState == ConnectionState.waiting)
              const ColoredBox(
                color: Color(0x22000000),
                child: Center(
                  child: SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

Widget _previewFallback() {
  return const ColoredBox(
    color: AppColors.canvas,
    child: Center(
      child: Icon(
        Icons.image_outlined,
        size: 22,
        color: AppColors.textSecondary,
      ),
    ),
  );
}

String _remoteSessionPresetId(RemotePresetCatalogItem item) {
  return 'remote:${item.source.id}:${item.entry.id}';
}

enum _TrayPresetMenuAction { export, rename, delete }
