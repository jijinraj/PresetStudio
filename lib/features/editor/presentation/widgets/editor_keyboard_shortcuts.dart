import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/editor_controller.dart';

class EditorKeyboardShortcuts extends StatelessWidget {
  const EditorKeyboardShortcuts({
    required this.controller,
    required this.child,
    super.key,
  });

  final EditorController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): _redo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
        const SingleActivator(LogicalKeyboardKey.bracketLeft, control: true):
            _rotateCounterClockwise,
        const SingleActivator(LogicalKeyboardKey.bracketRight, control: true):
            _rotateClockwise,
      },
      child: Focus(autofocus: true, child: child),
    );
  }

  void _undo() {
    if (!_canHandleShortcut()) {
      return;
    }

    controller.undo();
  }

  void _redo() {
    if (!_canHandleShortcut()) {
      return;
    }

    controller.redo();
  }

  void _rotateCounterClockwise() {
    if (!_canHandleShortcut()) {
      return;
    }

    controller.updateTransform(
      controller.session.transform.rotateCounterClockwise(),
    );
  }

  void _rotateClockwise() {
    if (!_canHandleShortcut()) {
      return;
    }

    controller.updateTransform(controller.session.transform.rotateClockwise());
  }

  bool _canHandleShortcut() {
    if (!controller.session.hasImage) {
      return false;
    }

    if (_isEditingText()) {
      return false;
    }

    return true;
  }

  bool _isEditingText() {
    final focusContext = FocusManager.instance.primaryFocus?.context;

    if (focusContext == null) {
      return false;
    }

    if (focusContext.widget is EditableText) {
      return true;
    }

    return focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }
}
