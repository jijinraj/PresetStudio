import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: const Center(child: Text('Editor workspace')),
    );
  }
}
