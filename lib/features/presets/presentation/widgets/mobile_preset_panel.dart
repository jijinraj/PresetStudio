import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_radii.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../../editor/application/editor_controller.dart';
import '../../../editor/domain/image_adjustments.dart';
import '../../../editor/presentation/widgets/editor_crop_preview.dart';
import '../../application/preset_adjustment_mapper.dart';
import '../../application/preset_library_controller.dart';
import '../../application/preset_remote_controller.dart';
import '../../domain/preset.dart';
import '../../domain/preset_record.dart';
import 'preset_library_view.dart';

/// Mobile-first preset browser used inside the editor's contextual tool panel.
///
/// This widget owns only browsing/presentation state. Applying, saving and
/// persistence continue through the existing editor and preset controllers.
class MobilePresetPanel extends StatefulWidget {
  const MobilePresetPanel({
    required this.libraryController,
    required this.editorController,
    this.remoteController,
    super.key,
  });

  final PresetLibraryController libraryController;
  final EditorController editorController;
  final PresetRemoteController? remoteController;

  @override
  State<MobilePresetPanel> createState() => _MobilePresetPanelState();
}

class _MobilePresetPanelState extends State<MobilePresetPanel> {
  static const String _allCategoryKey = 'all';
  static const String _savedCategoryKey = 'saved';

  String _selectedCategory = _allCategoryKey;
  String? _busyRemoteKey;

  @override
  Widget build(BuildContext context) {
    final remote = widget.remoteController;

    Widget buildLocal() {
      return AnimatedBuilder(
        animation: widget.libraryController,
        builder: (context, _) {
          return AnimatedBuilder(
            animation: widget.editorController,
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
    final library = widget.libraryController;

    if (library.isLoading) {
      return const Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (!library.isReady && library.errorMessage != null) {
      return Center(
        child: TextButton.icon(
          key: const ValueKey('mobile-preset-library-retry'),
          onPressed: library.retryInitialize,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry preset library'),
        ),
      );
    }

    final remoteItems =
        widget.remoteController?.items ?? const <RemotePresetCatalogItem>[];
    final categories = _categoriesFor(remoteItems);
    final selectedCategory =
        categories.any((category) => category.key == _selectedCategory)
        ? _selectedCategory
        : _allCategoryKey;

    if (selectedCategory != _selectedCategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedCategory = selectedCategory;
          });
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CategoryStrip(
            categories: categories,
            selectedKey: selectedCategory,
            onSelected: (key) {
              setState(() {
                _selectedCategory = key;
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _buildPresetStrip(
              context,
              selectedCategory: selectedCategory,
              remoteItems: remoteItems,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildPresetStrip(
    BuildContext context, {
    required String selectedCategory,
    required List<RemotePresetCatalogItem> remoteItems,
  }) {
    final records = widget.libraryController.records;
    final cards = <Widget>[];

    if (selectedCategory == _allCategoryKey) {
      cards.add(
        _OriginalPresetCard(
          editorController: widget.editorController,
          onApply: widget.editorController.session.hasImage
              ? widget.editorController.resetAdjustments
              : null,
        ),
      );

      for (final record in _standaloneLocalRecords(records, remoteItems)) {
        cards.add(
          _LocalMobilePresetCard(
            record: record,
            editorController: widget.editorController,
            isActive: _isLocalRecordActive(record),
            onApply: () => _applyLocal(record),
          ),
        );
      }

      for (final item in remoteItems) {
        cards.add(_remoteCard(context, item));
      }
    } else if (selectedCategory == _savedCategoryKey) {
      for (final record in records) {
        cards.add(
          _LocalMobilePresetCard(
            record: record,
            editorController: widget.editorController,
            isActive: _isLocalRecordActive(record),
            onApply: () => _applySavedRecord(record),
          ),
        );
      }
    } else {
      for (final item in remoteItems.where(
        (item) =>
            item.entry.tags.any((tag) => _tagKey(tag) == selectedCategory),
      )) {
        cards.add(_remoteCard(context, item));
      }
    }

    if (cards.isEmpty) {
      return Center(
        child: Text(
          selectedCategory == _savedCategoryKey
              ? 'No saved presets yet.'
              : 'No presets in this category.',
          style: AppTypography.bodyMuted,
        ),
      );
    }

    return ListView.separated(
      key: const ValueKey('mobile-preset-strip'),
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      itemCount: cards.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _remoteCard(BuildContext context, RemotePresetCatalogItem item) {
    final library = widget.libraryController;
    final remote = widget.remoteController!;
    final saved = library.remoteRecordFor(
      sourceId: item.source.id,
      remotePresetId: item.entry.id,
    );
    final savedRevision = saved?.origin.remoteRevision;
    final savedCurrent =
        savedRevision != null && savedRevision >= item.entry.revision;
    final updateAvailable =
        savedRevision != null && savedRevision < item.entry.revision;
    final key = _remoteSessionPresetId(item);
    final busy = _busyRemoteKey == key || remote.isSaving(item);

    return _RemoteMobilePresetCard(
      item: item,
      editorController: widget.editorController,
      remoteController: remote,
      savedPreset: saved?.preset,
      savedCurrent: savedCurrent,
      updateAvailable: updateAvailable,
      isBusy: busy,
      isActive: widget.editorController.session.activePresetId == key,
      onApply: widget.editorController.session.hasImage && !busy
          ? () => _applyRemote(context, item)
          : null,
      onSave: savedCurrent || busy ? null : () => _saveRemote(context, item),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final hasImage = widget.editorController.session.hasImage;
    final canSaveCurrent = hasImage && widget.libraryController.isReady;

    return Row(
      children: [
        TextButton.icon(
          key: const ValueKey('mobile-preset-save-current'),
          onPressed: canSaveCurrent ? () => _saveCurrent(context) : null,
          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
          label: const Text('Save current'),
        ),
        const Spacer(),
        IconButton(
          key: const ValueKey('mobile-preset-manage'),
          onPressed: () => _showManageSheet(context),
          tooltip: 'Manage presets',
          icon: const Icon(Icons.tune_rounded, size: 19),
        ),
      ],
    );
  }

  List<_MobilePresetCategory> _categoriesFor(
    List<RemotePresetCatalogItem> items,
  ) {
    final counts = <String, int>{};
    final labels = <String, String>{};

    for (final item in items) {
      for (final tag in item.entry.tags) {
        final key = _tagKey(tag);
        if (key.isEmpty || key == _allCategoryKey || key == _savedCategoryKey) {
          continue;
        }
        counts.update(key, (value) => value + 1, ifAbsent: () => 1);
        labels.putIfAbsent(key, () => _humanizeTag(tag));
      }
    }

    final rankedTags = counts.keys.toList()
      ..sort((a, b) {
        final countCompare = counts[b]!.compareTo(counts[a]!);
        if (countCompare != 0) {
          return countCompare;
        }
        return labels[a]!.toLowerCase().compareTo(labels[b]!.toLowerCase());
      });

    return <_MobilePresetCategory>[
      const _MobilePresetCategory(key: _allCategoryKey, label: 'All'),
      const _MobilePresetCategory(key: _savedCategoryKey, label: 'Saved'),
      for (final key in rankedTags.take(8))
        _MobilePresetCategory(key: key, label: labels[key]!),
    ];
  }

  List<PresetRecord> _standaloneLocalRecords(
    List<PresetRecord> records,
    List<RemotePresetCatalogItem> remoteItems,
  ) {
    return records
        .where((record) {
          if (record.origin.type != PresetOriginType.remoteInstalled) {
            return true;
          }

          final sourceId = record.origin.sourceId;
          final remotePresetId = record.origin.remotePresetId;
          if (sourceId == null || remotePresetId == null) {
            return true;
          }

          return !remoteItems.any(
            (item) =>
                item.source.id == sourceId && item.entry.id == remotePresetId,
          );
        })
        .toList(growable: false);
  }

  bool _isLocalRecordActive(PresetRecord record) {
    final activeId = widget.editorController.session.activePresetId;
    if (activeId == record.libraryId) {
      return true;
    }

    final origin = record.origin;
    if (origin.type != PresetOriginType.remoteInstalled) {
      return false;
    }

    final sourceId = origin.sourceId;
    final remotePresetId = origin.remotePresetId;
    if (sourceId == null || remotePresetId == null) {
      return false;
    }

    return activeId == 'remote:$sourceId:$remotePresetId';
  }

  void _applyLocal(PresetRecord record) {
    if (!widget.editorController.session.hasImage) {
      return;
    }

    widget.editorController.applyPreset(
      presetId: record.libraryId,
      presetName: record.preset.name,
      adjustments: PresetAdjustmentMapper.toImageAdjustments(
        record.preset.adjustments,
      ),
    );
  }

  void _applySavedRecord(PresetRecord record) {
    final origin = record.origin;
    if (origin.type == PresetOriginType.remoteInstalled &&
        origin.sourceId != null &&
        origin.remotePresetId != null) {
      widget.editorController.applyPreset(
        presetId: 'remote:${origin.sourceId}:${origin.remotePresetId}',
        presetName: record.preset.name,
        adjustments: PresetAdjustmentMapper.toImageAdjustments(
          record.preset.adjustments,
        ),
      );
      return;
    }

    _applyLocal(record);
  }

  Future<void> _applyRemote(
    BuildContext context,
    RemotePresetCatalogItem item,
  ) async {
    final remote = widget.remoteController;
    if (remote == null || !widget.editorController.session.hasImage) {
      return;
    }

    final busyKey = _remoteSessionPresetId(item);
    setState(() {
      _busyRemoteKey = busyKey;
    });

    try {
      final saved = widget.libraryController.remoteRecordFor(
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

      if (!mounted) {
        return;
      }

      widget.editorController.applyPreset(
        presetId: busyKey,
        presetName: preset.name,
        adjustments: PresetAdjustmentMapper.toImageAdjustments(
          preset.adjustments,
        ),
      );
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not apply preset: $error');
      }
    } finally {
      if (mounted && _busyRemoteKey == busyKey) {
        setState(() {
          _busyRemoteKey = null;
        });
      }
    }
  }

  Future<void> _saveRemote(
    BuildContext context,
    RemotePresetCatalogItem item,
  ) async {
    final remote = widget.remoteController;
    if (remote == null || remote.isSaving(item)) {
      return;
    }

    try {
      final record = await remote.save(
        item,
        libraryController: widget.libraryController,
      );
      if (context.mounted) {
        _showMessage(context, '${record.preset.name} saved for offline use.');
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
      await widget.libraryController.saveCurrent(
        name: draft.name,
        description: draft.description,
        adjustments: widget.editorController.session.adjustments,
      );
      if (context.mounted) {
        _showMessage(context, '${draft.name} saved.');
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not save preset: $error');
      }
    }
  }

  Future<void> _showManageSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: PresetLibraryView(
                libraryController: widget.libraryController,
                remoteController: widget.remoteController,
                editorController: widget.editorController,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _tagKey(String tag) => tag.trim().toLowerCase();

  static String _humanizeTag(String tag) {
    final normalized = tag.trim().replaceAll(RegExp(r'[-_]+'), ' ');
    if (normalized.isEmpty) {
      return normalized;
    }

    return normalized
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static String _remoteSessionPresetId(RemotePresetCatalogItem item) {
    return 'remote:${item.source.id}:${item.entry.id}';
  }
}

class _MobilePresetCategory {
  const _MobilePresetCategory({required this.key, required this.label});

  final String key;
  final String label;
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selectedKey,
    required this.onSelected,
  });

  final List<_MobilePresetCategory> categories;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        key: const ValueKey('mobile-preset-categories'),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category.key == selectedKey;

          return Material(
            color: selected ? AppColors.accentMuted : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              key: ValueKey('mobile-preset-category-${category.key}'),
              onTap: () => onSelected(category.key),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: Text(
                  category.label,
                  style: AppTypography.label.copyWith(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OriginalPresetCard extends StatelessWidget {
  const _OriginalPresetCard({
    required this.editorController,
    required this.onApply,
  });

  final EditorController editorController;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final active =
        editorController.session.activePresetId == null &&
        editorController.session.adjustments.isDefault;

    return _MobilePresetCardFrame(
      key: const ValueKey('mobile-preset-original'),
      name: 'Original',
      active: active,
      onTap: onApply,
      preview: _CurrentImagePresetPreview(
        editorController: editorController,
        adjustments: ImageAdjustments.initial,
      ),
    );
  }
}

class _LocalMobilePresetCard extends StatelessWidget {
  const _LocalMobilePresetCard({
    required this.record,
    required this.editorController,
    required this.isActive,
    required this.onApply,
  });

  final PresetRecord record;
  final EditorController editorController;
  final bool isActive;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return _MobilePresetCardFrame(
      key: ValueKey('mobile-preset-local-${record.libraryId}'),
      name: record.preset.name,
      active: isActive,
      onTap: editorController.session.hasImage ? onApply : null,
      topRight: const _SavedBadge(),
      preview: _CurrentImagePresetPreview(
        editorController: editorController,
        adjustments: PresetAdjustmentMapper.toImageAdjustments(
          record.preset.adjustments,
        ),
      ),
    );
  }
}

class _RemoteMobilePresetCard extends StatelessWidget {
  const _RemoteMobilePresetCard({
    required this.item,
    required this.editorController,
    required this.remoteController,
    required this.savedPreset,
    required this.savedCurrent,
    required this.updateAvailable,
    required this.isBusy,
    required this.isActive,
    required this.onApply,
    required this.onSave,
  });

  final RemotePresetCatalogItem item;
  final EditorController editorController;
  final PresetRemoteController remoteController;
  final Preset? savedPreset;
  final bool savedCurrent;
  final bool updateAvailable;
  final bool isBusy;
  final bool isActive;
  final VoidCallback? onApply;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return _MobilePresetCardFrame(
      key: ValueKey('mobile-preset-remote-${item.source.id}-${item.entry.id}'),
      name: item.entry.name,
      active: isActive,
      onTap: onApply,
      topRight: _RemoteSaveButton(
        key: ValueKey('mobile-preset-save-${item.source.id}-${item.entry.id}'),
        savedCurrent: savedCurrent,
        updateAvailable: updateAvailable,
        isBusy: isBusy,
        onPressed: onSave,
      ),
      preview: _RemoteCurrentImagePreview(
        item: item,
        editorController: editorController,
        remoteController: remoteController,
        savedPreset: savedPreset,
      ),
    );
  }
}

class _MobilePresetCardFrame extends StatelessWidget {
  const _MobilePresetCardFrame({
    required this.name,
    required this.active,
    required this.preview,
    required this.onTap,
    this.topRight,
    super.key,
  });

  final String name;
  final bool active;
  final Widget preview;
  final VoidCallback? onTap;
  final Widget? topRight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.all(active ? 2 : 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: active ? AppColors.accent : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.lg - 2),
                        child: preview,
                      ),
                    ),
                    if (topRight != null)
                      Positioned(
                        top: AppSpacing.xxs,
                        right: AppSpacing.xxs,
                        child: topRight!,
                      ),
                    if (active)
                      const Positioned(
                        left: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                        child: _ActiveBadge(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(
                  color: active
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentImagePresetPreview extends StatelessWidget {
  const _CurrentImagePresetPreview({
    required this.editorController,
    required this.adjustments,
  });

  final EditorController editorController;
  final ImageAdjustments adjustments;

  @override
  Widget build(BuildContext context) {
    final path = editorController.session.sourceImagePath;
    if (path == null) {
      return _previewFallback();
    }

    return ColoredBox(
      color: AppColors.canvas,
      child: EditorCropPreview(
        sourceImagePath: path,
        adjustments: adjustments,
        transform: editorController.session.transform,
        crop: editorController.session.crop,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _previewFallback(),
      ),
    );
  }
}

class _RemoteCurrentImagePreview extends StatelessWidget {
  const _RemoteCurrentImagePreview({
    required this.item,
    required this.editorController,
    required this.remoteController,
    required this.savedPreset,
  });

  final RemotePresetCatalogItem item;
  final EditorController editorController;
  final PresetRemoteController remoteController;
  final Preset? savedPreset;

  @override
  Widget build(BuildContext context) {
    final path = editorController.session.sourceImagePath;
    final savedRevision = savedPreset?.revision;
    final livePreviewFuture = path == null
        ? Future<Preset?>.value(null)
        : savedPreset != null &&
              savedRevision != null &&
              savedRevision >= item.entry.revision
        ? Future<Preset?>.value(savedPreset)
        : remoteController.presetForPreview(item);

    return FutureBuilder<Preset?>(
      future: livePreviewFuture,
      builder: (context, presetSnapshot) {
        final preset = presetSnapshot.data;

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
              const Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RemoteSaveButton extends StatelessWidget {
  const _RemoteSaveButton({
    required this.savedCurrent,
    required this.updateAvailable,
    required this.isBusy,
    required this.onPressed,
    super.key,
  });

  final bool savedCurrent;
  final bool updateAvailable;
  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.78),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: 34,
          child: Center(
            child: isBusy
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
                    size: 17,
                    color: savedCurrent
                        ? AppColors.accent
                        : AppColors.textPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SavedBadge extends StatelessWidget {
  const _SavedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.78),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.bookmark, size: 15, color: AppColors.accent),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 14, color: AppColors.onAccent),
    );
  }
}

Widget _previewFallback() {
  return const ColoredBox(
    color: AppColors.surfaceElevated,
    child: Center(
      child: Icon(
        Icons.photo_outlined,
        size: 24,
        color: AppColors.textDisabled,
      ),
    ),
  );
}
