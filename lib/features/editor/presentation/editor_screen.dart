import 'package:flutter/material.dart';

import '../application/editor_controller.dart';
import '../infrastructure/local_image_importer.dart';
import 'widgets/editor_shell.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final EditorController _controller = EditorController();
  final LocalImageImporter _imageImporter = const LocalImageImporter();

  bool _isImporting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return EditorShell(
      controller: _controller,
      onImportImage: _importImage,
      isImporting: _isImporting,
    );
  }
}
