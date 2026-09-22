import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../features/editor/presentation/editor_screen.dart';
import '../theme/preset_studio_theme.dart';

class PresetStudioApp extends StatelessWidget {
  const PresetStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: PresetStudioTheme.light,
      home: const EditorScreen(),
    );
  }
}
