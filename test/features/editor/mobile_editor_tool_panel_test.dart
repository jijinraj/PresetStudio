import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_tool_panel.dart';
import 'package:presetstudio/theme/preset_studio_theme.dart';

void main() {
  testWidgets('context tool panel exposes child while visible', (tester) async {
    var closeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: MobileEditorToolPanel(
              visible: true,
              title: 'Presets',
              onClose: () {
                closeCount += 1;
              },
              child: const SizedBox(
                height: 120,
                child: Center(child: Text('Panel content')),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('mobile-context-tool-panel')),
      findsOneWidget,
    );
    expect(find.text('Panel content'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mobile-context-panel-close')));
    expect(closeCount, 1);
  });

  testWidgets('hidden context tool panel ignores interaction', (tester) async {
    var closeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: Scaffold(
          body: MobileEditorToolPanel(
            visible: false,
            title: 'Presets',
            onClose: () {
              closeCount += 1;
            },
            child: const SizedBox(height: 120),
          ),
        ),
      ),
    );

    final ignorePointer = tester.widget<IgnorePointer>(
      find
          .descendant(
            of: find.byType(MobileEditorToolPanel),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );

    expect(ignorePointer.ignoring, isTrue);
    expect(closeCount, 0);
  });
}
