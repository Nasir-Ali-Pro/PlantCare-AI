import 'package:flutter/material.dart';

/// Semantic color tokens for the PlantCare botanical palette.
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF4A7C59);
  static const Color primaryLight = Color(0xFF6B9E78);
  static const Color primaryDark = Color(0xFF345740);
  static const Color primaryGlow = Color(0xFF4A7C59); // used for glow shadows

  // Secondary
  static const Color secondary = Color(0xFFA3B18A);

  // Background & Surface
  static const Color background = Color(0xFF111611);
  static const Color backgroundLight = Color(0xFF181E18);
  static const Color surface = Color(0xFF1C231C);
  static const Color surfaceElevated = Color(0xFF222A22);
  static const Color surfaceHighlight = Color(0xFF29322A);
  static const Color surfaceGlass = Color(0x661C231C); // semi-transparent glass

  // Text
  static const Color onSurface = Color(0xFFE8E4DA);
  static const Color onSurfaceMuted = Color(0xFF9CA396);
  static const Color onSurfaceFaint = Color(0xFF5C6358);
  static const Color onPrimary = Colors.white;

  // Borders
  static const Color border = Color(0xFF2A342A);
  static const Color borderLight = Color(0xFF36423A);

  // Semantic
  static const Color success = Color(0xFF4A7C59);
  static const Color warning = Color(0xFFC4956A);
  static const Color danger = Color(0xFFB85450);
  static const Color dangerLight = Color(0xFFD4716D);
  static const Color info = Color(0xFF6B8DAD);

  // Accent
  static const Color accent = Color(0xFFC4956A);
  static const Color accentLight = Color(0xFFD4A87D);

  // Gradients helpers
  static const Color heroGradientStart = Color(0xFF1E2D20);
  static const Color heroGradientEnd = Color(0xFF111611);

  // Misc
  static const Color shimmer = Color(0xFF272F27);
  static const Color shimmerHighlight = Color(0xFF313A31);
  static const Color divider = Color(0xFF222A22);
}
