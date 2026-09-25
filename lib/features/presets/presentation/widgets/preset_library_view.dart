import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../../editor/application/editor_controller.dart';
import '../../application/preset_adjustment_mapper.dart';
import '../../application/preset_library_controller.dart';
import '../../domain/preset_record.dart';

class PresetLibraryView extends StatelessWidget {
  const PresetLibraryView({
    required this.libraryController,
    required this.editorController,
    this.onPresetApplied,
    this.showTitle = true,
    super.key,
  });

  final PresetLibraryController libraryController;
  final EditorController editorController;
  final VoidCallback? onPresetApplied;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
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
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('preset-save-current'),
            onPressed: hasImage && libraryController.isReady
                ? () => _saveCurrent(context)
                : null,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Save current'),
          ),
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
              Text(
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

    if (records.isEmpty) {
      return const Center(
        child: Text(
          'No presets yet.\nSave your current adjustments to get started.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted,
        ),
      );
    }

    return ListView.separated(
      key: const ValueKey('preset-library-list'),
      padding: EdgeInsets.zero,
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xxs),
      itemBuilder: (context, index) {
        final record = records[index];
        final isActive =
            editorController.session.activePresetId == record.libraryId;

        return _PresetTile(
          record: record,
          isActive: isActive,
          enabled: editorController.session.hasImage,
          onApply: () => _applyPreset(context, record),
          onRename: record.origin.isMutable
              ? () => _renamePreset(context, record)
              : null,
          onDelete: record.origin.type != PresetOriginType.builtIn
              ? () => _deletePreset(context, record)
              : null,
        );
      },
    );
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

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.record,
    required this.isActive,
    required this.enabled,
    required this.onApply,
    required this.onRename,
    required this.onDelete,
  });

  final PresetRecord record;
  final bool isActive;
  final bool enabled;
  final VoidCallback onApply;
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
              if (onRename != null || onDelete != null)
                PopupMenuButton<_PresetMenuAction>(
                  key: ValueKey('preset-menu-${record.libraryId}'),
                  tooltip: 'Preset options',
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  onSelected: (action) {
                    switch (action) {
                      case _PresetMenuAction.rename:
                        onRename?.call();
                      case _PresetMenuAction.delete:
                        onDelete?.call();
                    }
                  },
                  itemBuilder: (context) {
                    return [
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

enum _PresetMenuAction { rename, delete }

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
