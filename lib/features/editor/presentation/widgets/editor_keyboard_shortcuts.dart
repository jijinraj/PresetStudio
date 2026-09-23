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
        const SingleActivator(
          LogicalKeyboardKey.bracketLeft,
          control: true,
        ): () {
          _rotateCounterClockwise();
        },
        const SingleActivator(
          LogicalKeyboardKey.bracketRight,
          control: true,
        ): () {
          _rotateClockwise();
        },
      },
      child: Focus(autofocus: true, child: child),
    );
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
    if (controller.session.sourceImagePath == null) {
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
