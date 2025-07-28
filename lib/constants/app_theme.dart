// lib/constants/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF31C5F4);
  static const Color background = Color(0xFFFFFFFF);

  // Green Colors
  static const Color lightGreen = Color(0xFFD3FFD0);
  static const Color darkGreen = Color(0xFF0BB908);

  // Red Colors
  static const Color lightRed = Color(0xFFFFD0D1);
  static const Color darkRed = Color(0xFFFF6366);

  // Yellow Colors
  static const Color lightYellow = Color(0xFFFFDB7F);
  static const Color darkYellow = Color(0xFFB57F00);

  // Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF656565);
  static const Color textTertiary = Color(0xFF222222);
  static const Color textAccent = Color(0xFF03AEFF);
  static const Color textSuccess = Color(0xFF0BB908);
  static const Color textError = Color(0xFFFF6366);
  static const Color textWarning = Color(0xFFB57F00);

  // Additional helpful colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Colors.transparent;

  static var grey;

  static var accent;
}

class AppFonts {
  // Font Family
  static const String familyName = 'Familjen Grotesk';

  // Font Sizes
  static const double size13 = 13.0;
  static const double size14 = 14.0;
  static const double size16 = 16.0;
  static const double size18 = 18.0;
  static const double size20 = 20.0;
  static const double size24 = 24.0; // Assuming 2r means 24

  // Text Styles - Regular
  static TextStyle regular13({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size13,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle regular14({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size14,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle regular16({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size16,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle regular18({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size18,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle regular20({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size20,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle regular24({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size24,
    fontWeight: FontWeight.w400,
    color: color ?? AppColors.textPrimary,
  );

  // Text Styles - SemiBold
  static TextStyle semiBold13({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size13,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle semiBold14({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size14,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle semiBold16({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size16,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle semiBold18({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size18,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle semiBold20({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size20,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle semiBold24({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size24,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.textPrimary,
  );

  // Text Styles - Bold
  static TextStyle bold13({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size13,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle bold14({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size14,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle bold16({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size16,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle bold18({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size18,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle bold20({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size20,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle bold24({Color? color}) => GoogleFonts.familjenGrotesk(
    fontSize: size24,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.textPrimary,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        surface: AppColors.background,
        onPrimary: AppColors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: AppFonts.bold24(),
        displayMedium: AppFonts.bold20(),
        displaySmall: AppFonts.bold18(),
        headlineLarge: AppFonts.semiBold20(),
        headlineMedium: AppFonts.semiBold18(),
        headlineSmall: AppFonts.semiBold16(),
        titleLarge: AppFonts.semiBold16(),
        titleMedium: AppFonts.semiBold14(),
        titleSmall: AppFonts.semiBold13(),
        bodyLarge: AppFonts.regular16(),
        bodyMedium: AppFonts.regular14(),
        bodySmall: AppFonts.regular13(),
        labelLarge: AppFonts.semiBold14(),
        labelMedium: AppFonts.regular14(),
        labelSmall: AppFonts.regular13(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: AppFonts.semiBold16(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleTextStyle: AppFonts.semiBold18(color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      useMaterial3: true,
    );
  }
}

// Usage Extension for easier access
extension AppTextStyles on TextStyle {
  TextStyle get primary => copyWith(color: AppColors.textPrimary);
  TextStyle get secondary => copyWith(color: AppColors.textSecondary);
  TextStyle get tertiary => copyWith(color: AppColors.textTertiary);
  TextStyle get accent => copyWith(color: AppColors.textAccent);
  TextStyle get success => copyWith(color: AppColors.textSuccess);
  TextStyle get error => copyWith(color: AppColors.textError);
  TextStyle get warning => copyWith(color: AppColors.textWarning);
}
