import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_image_viewport.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_canvas.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_shell.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_tool_panel.dart';
import 'package:presetstudio/theme/preset_studio_theme.dart';
import 'package:presetstudio/theme/tokens/app_colors.dart';
import 'package:presetstudio/theme/tokens/app_radii.dart';
import 'package:presetstudio/theme/tokens/app_spacing.dart';

void main() {
  testWidgets('mobile editor uses image-first adaptive canvas presentation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = EditorController();
    addTearDown(controller.dispose);
    controller.setSourceImage('missing-mobile-layout-image.jpg');

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: MobileEditorShell(
          controller: controller,
          onImportImage: () async {},
          isImporting: false,
        ),
      ),
    );

    expect(find.byType(MobileEditorCanvas), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppColors.canvas);

    final frame = tester.widget<Padding>(
      find.byKey(const ValueKey('mobile-editor-canvas-frame')),
    );
    expect(
      frame.padding,
      const EdgeInsets.symmetric(horizontal: 0, vertical: AppSpacing.sm),
    );

    expect(find.byKey(const ValueKey('mobile-top-import')), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-bottom-dock')), findsOneWidget);
    expect(find.byType(MobileEditorToolPanel), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);

    final imageWorkspace = tester.widget<Padding>(
      find.byKey(const ValueKey('mobile-editor-image-workspace')),
    );
    final workspacePadding = imageWorkspace.padding as EdgeInsets;
    expect(workspacePadding.bottom, AppSpacing.sm);
    expect(workspacePadding.left, 0);
    expect(workspacePadding.right, 0);

    final viewport = tester.widget<EditorImageViewport>(
      find.byType(EditorImageViewport),
    );
    expect(viewport.contentPadding, EdgeInsets.zero);
    expect(viewport.imageFit, BoxFit.contain);
    expect(
      viewport.imageBorderRadius,
      BorderRadius.circular(AppRadii.editorImage),
    );

    await tester.pump();
    expect(
      find.byKey(const ValueKey('editor-viewport-image-clip')),
      findsOneWidget,
    );
  });
}
