import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_dimensions.dart';
import '../../../presets/application/preset_library_controller.dart';
import '../../../presets/application/preset_remote_controller.dart';
import '../../application/editor_controller.dart';
import 'desktop_editor_shell.dart';
import 'editor_keyboard_shortcuts.dart';
import 'mobile_editor_shell.dart';

class EditorShell extends StatelessWidget {
  const EditorShell({
    required this.controller,
    required this.presetLibraryController,
    this.presetRemoteController,
    required this.onImportImage,
    required this.isImporting,
    this.onExportImage,
    this.isExporting = false,
    super.key,
  });

  final EditorController controller;
  final PresetLibraryController presetLibraryController;
  final PresetRemoteController? presetRemoteController;
  final Future<void> Function() onImportImage;
  final bool isImporting;
  final Future<void> Function()? onExportImage;
  final bool isExporting;

  @override
  Widget build(BuildContext context) {
    return EditorKeyboardShortcuts(
      controller: controller,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop =
              constraints.maxWidth >= AppDimensions.desktopBreakpoint;

          if (isDesktop) {
            return DesktopEditorShell(
              controller: controller,
              presetLibraryController: presetLibraryController,
              presetRemoteController: presetRemoteController,
              onImportImage: onImportImage,
              isImporting: isImporting,
              onExportImage: onExportImage,
              isExporting: isExporting,
            );
          }

          return MobileEditorShell(
            controller: controller,
            presetLibraryController: presetLibraryController,
            presetRemoteController: presetRemoteController,
            onImportImage: onImportImage,
            isImporting: isImporting,
            onExportImage: onExportImage,
            isExporting: isExporting,
          );
        },
      ),
    );
  }
}
