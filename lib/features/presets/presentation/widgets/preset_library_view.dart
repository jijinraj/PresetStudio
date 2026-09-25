import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../../editor/application/editor_controller.dart';
import '../../application/preset_adjustment_mapper.dart';
import '../../application/preset_file_gateway.dart';
import '../../application/preset_library_controller.dart';
import '../../application/preset_remote_controller.dart';
import '../../domain/preset_json_codec.dart';
import '../../domain/preset_record.dart';
import '../../infrastructure/local_preset_file_gateway.dart';

class PresetLibraryView extends StatelessWidget {
  const PresetLibraryView({
    required this.libraryController,
    required this.editorController,
    this.remoteController,
    this.fileGateway = const LocalPresetFileGateway(),
    this.onPresetApplied,
    this.showTitle = true,
    super.key,
  });

  final PresetLibraryController libraryController;
  final EditorController editorController;
  final PresetRemoteController? remoteController;
  final PresetFileGateway fileGateway;
  final VoidCallback? onPresetApplied;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final remote = remoteController;

    Widget buildLocal() {
      return AnimatedBuilder(
        animation: libraryController,
        builder: (context, _) {
          return AnimatedBuilder(
            animation: editorController,
            builder: (context, _) {
              return _buildContent(context);
            },
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
    final records = libraryController.records;
    final hasImage = editorController.session.hasImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            children: [
              const Expanded(
                child: Text('Presets', style: AppTypography.label),
              ),
              Text('${records.length}', style: AppTypography.bodyMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('preset-save-current'),
                onPressed: hasImage && libraryController.isReady
                    ? () => _saveCurrent(context)
                    : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Save current'),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton.outlined(
              key: const ValueKey('preset-import'),
              tooltip: 'Import preset',
              onPressed: libraryController.isReady
                  ? () => _importPreset(context)
                  : null,
              icon: const Icon(Icons.file_open_outlined, size: 18),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(child: _buildLibraryBody(context)),
      ],
    );
  }

  Widget _buildLibraryBody(BuildContext context) {
    if (libraryController.isLoading) {
      return const Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final error = libraryController.errorMessage;

    if (!libraryController.isReady && error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Preset library unavailable.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMuted,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                key: const ValueKey('preset-library-retry'),
                onPressed: libraryController.retryInitialize,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final records = libraryController.records;
    final remote = remoteController;
    final remoteItems = remote?.items ?? const <RemotePresetCatalogItem>[];

    if (records.isEmpty && remote == null) {
      return const Center(
        child: Text(
          'No presets yet.\nSave your current adjustments or import a preset.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted,
        ),
      );
    }

    return ListView(
      key: const ValueKey('preset-library-list'),
      padding: EdgeInsets.zero,
      children: [
        if (records.isNotEmpty) ...[
          const _PresetSectionLabel(label: 'My presets'),
          const SizedBox(height: AppSpacing.xxs),
          for (final record in records) ...[
            _buildLocalPresetTile(context, record),
            const SizedBox(height: AppSpacing.xxs),
          ],
        ] else ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'No local presets yet.',
              style: AppTypography.bodyMuted,
            ),
          ),
        ],
        if (remote != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _RemoteSectionHeader(
            isRefreshing: remote.isRefreshing,
            onRefresh: remote.isInitialized && !remote.isRefreshing
                ? () => remote.refresh()
                : null,
          ),
          const SizedBox(height: AppSpacing.xxs),
          if (remote.isInitializing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (remoteItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                remote.errorMessage != null || remote.sourceErrors.isNotEmpty
                    ? 'Remote presets are unavailable. Installed presets '
                          'still work offline.'
                    : 'No remote presets available.',
                style: AppTypography.bodyMuted,
              ),
            )
          else
            for (final item in remoteItems) ...[
              _buildRemotePresetTile(context, item),
              const SizedBox(height: AppSpacing.xxs),
            ],
        ],
      ],
    );
  }

  Widget _buildLocalPresetTile(BuildContext context, PresetRecord record) {
    final isActive =
        editorController.session.activePresetId == record.libraryId;

    return _PresetTile(
      record: record,
      isActive: isActive,
      enabled: editorController.session.hasImage,
      onApply: () => _applyPreset(context, record),
      onExport: () => _exportPreset(context, record),
      onRename: record.origin.isMutable
          ? () => _renamePreset(context, record)
          : null,
      onDelete: record.origin.type != PresetOriginType.builtIn
          ? () => _deletePreset(context, record)
          : null,
    );
  }

  Widget _buildRemotePresetTile(
    BuildContext context,
    RemotePresetCatalogItem item,
  ) {
    final remote = remoteController!;
    final installed = libraryController.remoteRecordFor(
      sourceId: item.source.id,
      remotePresetId: item.entry.id,
    );
    final installedRevision = installed?.origin.remoteRevision;
    final isCurrent =
        installed != null &&
        installedRevision != null &&
        installedRevision >= item.entry.revision;
    final isUpdate =
        installed != null &&
        installedRevision != null &&
        installedRevision < item.entry.revision;
    final isInstalling = remote.isInstalling(item);

    return _RemotePresetTile(
      item: item,
      state: isCurrent
          ? _RemotePresetState.installed
          : isUpdate
          ? _RemotePresetState.updateAvailable
          : _RemotePresetState.available,
      isBusy: isInstalling,
      onInstall: isCurrent || isInstalling
          ? null
          : () => _installRemotePreset(context, item),
    );
  }

  Future<void> _installRemotePreset(
    BuildContext context,
    RemotePresetCatalogItem item,
  ) async {
    final remote = remoteController;

    if (remote == null) {
      return;
    }

    try {
      final record = await remote.install(
        item,
        libraryController: libraryController,
      );

      if (context.mounted) {
        _showMessage(context, 'Installed ${record.preset.name}.');
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not install preset: $error');
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
      );

      if (!context.mounted) {
        return;
      }

      _showMessage(context, 'Preset saved.');
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

  void _applyPreset(BuildContext context, PresetRecord record) {
    if (!editorController.session.hasImage) {
      return;
    }

    editorController.applyPreset(
      presetId: record.libraryId,
      presetName: record.preset.name,
      adjustments: PresetAdjustmentMapper.toImageAdjustments(
        record.preset.adjustments,
      ),
    );

    _showMessage(context, 'Applied ${record.preset.name}.');
    onPresetApplied?.call();
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
              key: const ValueKey('preset-delete-confirm'),
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

class _PresetSectionLabel extends StatelessWidget {
  const _PresetSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTypography.label);
  }
}

class _RemoteSectionHeader extends StatelessWidget {
  const _RemoteSectionHeader({
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Text('Discover', style: AppTypography.label)),
        IconButton(
          key: const ValueKey('preset-remote-refresh'),
          tooltip: 'Refresh remote presets',
          visualDensity: VisualDensity.compact,
          onPressed: onRefresh,
          icon: isRefreshing
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh, size: 18),
        ),
      ],
    );
  }
}

enum _RemotePresetState { available, updateAvailable, installed }

class _RemotePresetTile extends StatelessWidget {
  const _RemotePresetTile({
    required this.item,
    required this.state,
    required this.isBusy,
    required this.onInstall,
  });

  final RemotePresetCatalogItem item;
  final _RemotePresetState state;
  final bool isBusy;
  final VoidCallback? onInstall;

  @override
  Widget build(BuildContext context) {
    final buttonLabel = switch (state) {
      _RemotePresetState.available => 'Install',
      _RemotePresetState.updateAvailable => 'Update',
      _RemotePresetState.installed => 'Installed',
    };

    return Container(
      key: ValueKey('preset-remote-${item.source.id}-${item.entry.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_download_outlined,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body,
                ),
                Text(
                  item.entry.author == null
                      ? item.source.name
                      : '${item.entry.author} · ${item.source.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMuted,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            key: ValueKey(
              'preset-remote-install-${item.source.id}-${item.entry.id}',
            ),
            onPressed: onInstall,
            child: isBusy
                ? const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.record,
    required this.isActive,
    required this.enabled,
    required this.onApply,
    required this.onExport,
    required this.onRename,
    required this.onDelete,
  });

  final PresetRecord record;
  final bool isActive;
  final bool enabled;
  final VoidCallback onApply;
  final VoidCallback onExport;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? AppColors.surfaceElevated : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        key: ValueKey('preset-apply-${record.libraryId}'),
        borderRadius: BorderRadius.circular(6),
        onTap: enabled ? onApply : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.auto_awesome_outlined,
                size: 18,
                color: isActive
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.preset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body,
                    ),
                    Text(
                      _originLabel(record),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMuted,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_PresetMenuAction>(
                key: ValueKey('preset-menu-${record.libraryId}'),
                tooltip: 'Preset options',
                iconSize: 18,
                padding: EdgeInsets.zero,
                onSelected: (action) {
                  switch (action) {
                    case _PresetMenuAction.export:
                      onExport();
                    case _PresetMenuAction.rename:
                      onRename?.call();
                    case _PresetMenuAction.delete:
                      onDelete?.call();
                  }
                },
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(
                      value: _PresetMenuAction.export,
                      child: Text('Export'),
                    ),
                    if (onRename != null)
                      const PopupMenuItem(
                        value: _PresetMenuAction.rename,
                        child: Text('Rename'),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: _PresetMenuAction.delete,
                        child: Text('Delete'),
                      ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _originLabel(PresetRecord record) {
    switch (record.origin.type) {
      case PresetOriginType.builtIn:
        return 'Built-in';
      case PresetOriginType.local:
        return 'My preset';
      case PresetOriginType.remoteInstalled:
        return record.origin.sourceId == null
            ? 'Installed'
            : 'Installed · ${record.origin.sourceId}';
    }
  }
}

enum _PresetMenuAction { export, rename, delete }

enum PresetImportConflictResolution { replace, importCopy }

Future<PresetImportConflictResolution?> showPresetImportConflictDialog(
  BuildContext context, {
  required String incomingName,
  required String existingName,
}) {
  return showDialog<PresetImportConflictResolution>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Preset already exists'),
        content: Text(
          'A local preset with the same preset ID already exists. '
          'Replace “$existingName” with “$incomingName”, or import it as '
          'a separate local copy?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('preset-import-copy'),
            onPressed: () =>
                Navigator.of(context)
                    .pop(PresetImportConflictResolution.importCopy),
            child: const Text('Import copy'),
          ),
          FilledButton(
            key: const ValueKey('preset-import-replace'),
            onPressed: () =>
                Navigator.of(context)
                    .pop(PresetImportConflictResolution.replace),
            child: const Text('Replace'),
          ),
        ],
      );
    },
  );
}

class PresetSaveDraft {
  const PresetSaveDraft({required this.name, this.description});

  final String name;
  final String? description;
}

Future<PresetSaveDraft?> showPresetSaveDialog(BuildContext context) {
  return showDialog<PresetSaveDraft>(
    context: context,
    builder: (context) => const _PresetSaveDialog(),
  );
}

class _PresetSaveDialog extends StatefulWidget {
  const _PresetSaveDialog();

  @override
  State<_PresetSaveDialog> createState() => _PresetSaveDialogState();
}

class _PresetSaveDialogState extends State<_PresetSaveDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _validationMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || name.length > 120) {
      setState(() {
        _validationMessage = 'Name must contain 1–120 characters.';
      });
      return;
    }

    if (description.length > 1000) {
      setState(() {
        _validationMessage = 'Description cannot exceed 1000 characters.';
      });
      return;
    }

    Navigator.of(context).pop(
      PresetSaveDraft(
        name: name,
        description: description.isEmpty ? null : description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Save preset'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('preset-save-name'),
              controller: _nameController,
              autofocus: true,
              maxLength: 120,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              key: const ValueKey('preset-save-description'),
              controller: _descriptionController,
              maxLength: 1000,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            if (_validationMessage != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _validationMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('preset-save-confirm'),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

Future<String?> showPresetRenameDialog(
  BuildContext context, {
  required String initialName,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _PresetRenameDialog(initialName: initialName),
  );
}

class _PresetRenameDialog extends StatefulWidget {
  const _PresetRenameDialog({required this.initialName});

  final String initialName;

  @override
  State<_PresetRenameDialog> createState() => _PresetRenameDialogState();
}

class _PresetRenameDialogState extends State<_PresetRenameDialog> {
  late final TextEditingController _controller;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();

    if (value.isEmpty || value.length > 120) {
      setState(() {
        _validationMessage = 'Name must contain 1–120 characters.';
      });
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Rename preset'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('preset-rename-name'),
              controller: _controller,
              autofocus: true,
              maxLength: 120,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            if (_validationMessage != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _validationMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('preset-rename-confirm'),
          onPressed: _submit,
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
