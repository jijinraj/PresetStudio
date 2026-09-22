import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../theme/tokens/app_colors.dart';
import '../../../theme/tokens/app_radii.dart';
import '../../../theme/tokens/app_spacing.dart';
import '../../../theme/tokens/app_typography.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: const Text('Editor workspace', style: AppTypography.bodyMuted),
        ),
      ),
    );
  }
}
