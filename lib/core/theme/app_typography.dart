import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'JetBrains Mono';

  static const TextStyle mono = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    letterSpacing: 1.2,
    color: AppColors.textSecondary,
  );

  static const TextStyle tab = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
  );
}
