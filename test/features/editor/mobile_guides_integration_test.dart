import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_shell.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_guides_panel.dart';
import 'package:presetstudio/theme/preset_studio_theme.dart';

void main() {
  testWidgets('mobile Guides mode is workspace-only and shared with Crop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final editor = EditorController();
    addTearDown(editor.dispose);
    editor.setSourceImage('missing-mobile-guides-image.jpg');
    final initialHistoryLength = editor.history.length;
    final initialSession = editor.session;

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: MobileEditorShell(
          controller: editor,
          onImportImage: () async {},
          isImporting: false,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('mobile-tool-guides')));
    await tester.pump();

    expect(find.byType(MobileGuidesPanel), findsOneWidget);
    expect(
      find.byKey(const ValueKey('composition-guide-rule-of-thirds-overlay')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('mobile-guide-none')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('composition-guide-rule-of-thirds-overlay')),
      findsNothing,
    );
    expect(editor.session, initialSession);
    expect(editor.history, hasLength(initialHistoryLength));

    await tester.tap(find.byKey(const ValueKey('mobile-tool-crop')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('composition-guide-none-overlay')),
      findsOneWidget,
    );
    expect(editor.session, initialSession);
    expect(editor.history, hasLength(initialHistoryLength));

    await tester.tap(find.byKey(const ValueKey('crop-cancel')));
    await tester.pumpAndSettle();
    expect(editor.session, initialSession);
    expect(editor.history, hasLength(initialHistoryLength));
  });
}
