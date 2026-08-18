import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Legacy aliases — referenced by existing screens.
  static const Color primaryGreen = AppColors.primary;
  static const Color primaryDarkGreen = AppColors.primaryDark;
  static const Color accentAmber = AppColors.warning;
  static const Color dangerRed = AppColors.danger;
  static const Color bgDarkStart = AppColors.background;
  static const Color bgDarkEnd = AppColors.backgroundLight;
  static const Color surfaceColor = AppColors.surface;
  static const Color borderTransparent = AppColors.border;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [AppColors.warning, AppColors.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [AppColors.background, AppColors.backgroundLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient scanGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: AppColors.primary.withValues(alpha: 0.04),

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.danger,
        onError: Colors.white,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.dmSerifDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.dmSerifDisplay(
          fontSize: 26,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          letterSpacing: -0.1,
        ),
        titleSmall: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.onSurface,
          height: 1.55,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 14,
          color: AppColors.onSurfaceMuted,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.nunito(
          fontSize: 12,
          color: AppColors.onSurfaceMuted,
          height: 1.45,
        ),
        labelLarge: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceMuted,
        ),
        labelSmall: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceFaint,
          letterSpacing: 0.8,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurface, size: 22),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 8,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHighlight,
        contentTextStyle: GoogleFonts.nunito(
          fontSize: 14,
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHighlight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.nunito(
          fontSize: 14,
          color: AppColors.onSurfaceFaint,
        ),
        labelStyle: GoogleFonts.nunito(
          fontSize: 14,
          color: AppColors.onSurfaceMuted,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceHighlight,
        selectedColor: AppColors.primary.withValues(alpha: 0.22),
        side: const BorderSide(color: AppColors.border),
        labelStyle: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(88, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(88, 52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          textStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
