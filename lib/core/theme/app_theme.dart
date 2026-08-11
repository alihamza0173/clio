import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      dividerColor: AppColors.border,
      textTheme: base.textTheme.apply(fontFamily: AppTypography.fontFamily),
      dividerTheme: const DividerThemeData(
        thickness: 0.5,
        color: AppColors.border,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        constraints: BoxConstraints(minWidth: 18, minHeight: 18),
        strokeWidth: 2,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: AppColors.background,
        hintStyle: AppTypography.tab.copyWith(color: AppColors.textMuted),
        contentPadding: const .symmetric(horizontal: 10, vertical: 10),
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.primary),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: BorderSide(color: color),
  );
}
