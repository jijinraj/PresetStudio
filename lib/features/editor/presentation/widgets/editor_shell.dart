import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_dimensions.dart';
import '../../application/editor_controller.dart';
import 'desktop_editor_shell.dart';
import 'editor_keyboard_shortcuts.dart';
import 'mobile_editor_shell.dart';

class EditorShell extends StatelessWidget {
  const EditorShell({
    required this.controller,
    required this.onImportImage,
    required this.isImporting,
    super.key,
  });

  final EditorController controller;
  final Future<void> Function() onImportImage;
  final bool isImporting;

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
              onImportImage: onImportImage,
              isImporting: isImporting,
            );
          }

          return MobileEditorShell(
            controller: controller,
            onImportImage: onImportImage,
            isImporting: isImporting,
          );
        },
      ),
    );
  }
}
