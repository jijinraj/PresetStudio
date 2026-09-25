import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../application/editor_controller.dart';
import '../domain/export_settings.dart';
import '../infrastructure/local_image_exporter.dart';
import '../infrastructure/local_image_importer.dart';
import '../rendering/export_background_renderer.dart';
import '../rendering/export_image_renderer.dart';
import '../../presets/application/preset_library.dart';
import '../../presets/application/preset_library_controller.dart';
import '../../presets/application/preset_remote_controller.dart';
import '../../presets/infrastructure/http_preset_remote_gateway.dart';
import '../../presets/infrastructure/local_preset_catalog_cache.dart';
import '../../presets/infrastructure/local_preset_library_store.dart';
import '../../presets/infrastructure/local_preset_source_store.dart';
import 'widgets/editor_shell.dart';
import 'widgets/export_settings_dialog.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final EditorController _controller = EditorController();
  final LocalImageImporter _imageImporter = const LocalImageImporter();
  final LocalImageExporter _imageExporter = const LocalImageExporter();
  late final PresetLibraryController _presetLibraryController;
  late final PresetRemoteController _presetRemoteController;

  bool _isImporting = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _presetLibraryController = PresetLibraryController(
      libraryLoader: () async {
        final store = await LocalPresetLibraryStore.openDefault();
        return PresetLibrary(store: store);
      },
    );
    _presetRemoteController = PresetRemoteController(
      sourceStoreLoader: LocalPresetSourceStore.openDefault,
      catalogCacheLoader: LocalPresetCatalogCache.openDefault,
      gateway: HttpPresetRemoteGateway(),
    );

    unawaited(_initializePresetServices());
  }

  @override
  void dispose() {
    _presetRemoteController.dispose();
    _presetLibraryController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializePresetServices() async {
    await Future.wait([
      _presetLibraryController.initialize(),
      _presetRemoteController.initialize(),
    ]);

    if (_presetRemoteController.isInitialized) {
      unawaited(_presetRemoteController.refresh());
    }
  }

  Future<void> _importImage() async {
    if (_isImporting) {
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final path = await _imageImporter.pickImage();

      if (path == null) {
        return;
      }

      _controller.setSourceImage(path);
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<void> _exportImage() async {
    if (_isExporting || !_controller.session.hasImage) {
      return;
    }

    final settings = await showExportSettingsDialog(
      context,
      initialSettings: _controller.session.exportSettings,
    );

    if (!mounted || settings == null) {
      return;
    }

    _controller.updateExportSettings(settings);

    final session = _controller.session;
    final sourceImagePath = session.sourceImagePath;

    if (sourceImagePath == null) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final sourceBytes = await File(sourceImagePath).readAsBytes();
      final result = await renderExportInBackground(
        sourceBytes: sourceBytes,
        session: session,
      );

      if (!mounted) {
        return;
      }

      final destination = await _imageExporter.saveImage(
        bytes: result.bytes,
        format: result.plan.format,
        sourceImagePath: sourceImagePath,
      );

      if (!mounted || destination == null) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${result.plan.format.label} · '
              '${result.plan.outputWidth} × ${result.plan.outputHeight}',
            ),
          ),
        );
    } on ExportImageRenderException catch (error) {
      if (mounted) {
        _showExportError(error.message);
      }
    } on FileSystemException {
      if (mounted) {
        _showExportError('The source image could not be read.');
      }
    } on Object catch (error, stackTrace) {
      debugPrint('Export failed: $error\n$stackTrace');
      if (mounted) {
        _showExportError(
          'Export failed. Check the debug console for the underlying error.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showExportError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return EditorShell(
      controller: _controller,
      presetLibraryController: _presetLibraryController,
      presetRemoteController: _presetRemoteController,
      onImportImage: _importImage,
      isImporting: _isImporting,
      onExportImage: _exportImage,
      isExporting: _isExporting,
    );
  }
}
