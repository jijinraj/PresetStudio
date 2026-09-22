import 'package:flutter/material.dart';

import '../../../../theme/tokens/app_dimensions.dart';
import 'desktop_editor_shell.dart';
import 'mobile_editor_shell.dart';

class EditorShell extends StatelessWidget {
  const EditorShell({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= AppDimensions.desktopBreakpoint;

        if (isDesktop) {
          return const DesktopEditorShell();
        }

        return const MobileEditorShell();
      },
    );
  }
}
