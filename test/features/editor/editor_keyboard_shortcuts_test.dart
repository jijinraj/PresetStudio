import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_keyboard_shortcuts.dart';

void main() {
  group('EditorKeyboardShortcuts', () {
    testWidgets('Ctrl + ] rotates the image clockwise by 90 degrees', (
      tester,
    ) async {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('test-image.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: EditorKeyboardShortcuts(
            controller: controller,
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      );

      await tester.pump();

      await _sendControlShortcut(tester, LogicalKeyboardKey.bracketRight);

      expect(controller.session.transform.normalizedRotationDegrees, 90.0);
    });

    testWidgets('Ctrl + [ rotates the image counter-clockwise by 90 degrees', (
      tester,
    ) async {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('test-image.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: EditorKeyboardShortcuts(
            controller: controller,
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      );

      await tester.pump();

      await _sendControlShortcut(tester, LogicalKeyboardKey.bracketLeft);

      expect(controller.session.transform.normalizedRotationDegrees, -90.0);
    });

    testWidgets('rotation shortcuts do nothing when no image is loaded', (
      tester,
    ) async {
      final controller = EditorController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: EditorKeyboardShortcuts(
            controller: controller,
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      );

      await tester.pump();

      await _sendControlShortcut(tester, LogicalKeyboardKey.bracketRight);

      expect(controller.session.transform.normalizedRotationDegrees, 0.0);
    });

    testWidgets('rotation shortcuts do not run while editing text', (
      tester,
    ) async {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('test-image.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: EditorKeyboardShortcuts(
            controller: controller,
            child: const Scaffold(
              body: TextField(key: ValueKey('test-text-field')),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('test-text-field')));

      await tester.pump();

      expect(FocusManager.instance.primaryFocus, isNotNull);

      await _sendControlShortcut(tester, LogicalKeyboardKey.bracketRight);

      expect(controller.session.transform.normalizedRotationDegrees, 0.0);
    });

    testWidgets('repeated clockwise shortcut uses transform wrapping', (
      tester,
    ) async {
      final controller = EditorController();
      addTearDown(controller.dispose);

      controller.setSourceImage('test-image.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: EditorKeyboardShortcuts(
            controller: controller,
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      );

      await tester.pump();

      await _sendControlShortcut(tester, LogicalKeyboardKey.bracketRight);

      expect(controller.session.transform.normalizedRotationDegrees, 90.0);

      await _sendControlShortcut(tester, LogicalKeyboardKey.bracketRight);

      expect(controller.session.transform.normalizedRotationDegrees, 180.0);

      await _sendControlShortcut(tester, LogicalKeyboardKey.bracketRight);

      expect(controller.session.transform.normalizedRotationDegrees, -90.0);

      await _sendControlShortcut(tester, LogicalKeyboardKey.bracketRight);

      expect(controller.session.transform.normalizedRotationDegrees, 0.0);
    });
  });
}

Future<void> _sendControlShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);

  await tester.sendKeyEvent(key);

  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

  await tester.pump();
}
