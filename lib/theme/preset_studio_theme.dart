import 'package:flutter/material.dart';

class PresetStudioTheme {
  const PresetStudioTheme._();

  static const Color background = Color(0xFFF7F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF171717);
  static const Color textSecondary = Color(0xFF737373);
  static const Color border = Color(0xFFE5E5E2);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: textPrimary,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      dividerColor: border,
    );
  }
}
