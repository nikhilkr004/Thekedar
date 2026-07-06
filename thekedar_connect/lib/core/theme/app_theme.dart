import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'design_system.dart';

// Riverpod stream provider to listen to theme configuration updates in real-time
final dynamicThemeProvider = StreamProvider<ThemeData>((ref) {
  return Supabase.instance.client
      .from('app_configurations')
      .stream(primaryKey: ['key'])
      .eq('key', 'platform_theme_tokens')
      .map((event) {
        if (event.isEmpty) return AppTheme.darkTheme;
        final config = event.first;
        final val = config['value'];
        if (val == null) return AppTheme.darkTheme;
        try {
          final Map<String, dynamic> tokens = jsonDecode(val);
          return AppTheme.buildDynamicTheme(tokens);
        } catch (_) {
          return AppTheme.darkTheme;
        }
      });
});

class AppTheme {
  /// Unified Dark Theme Configuration (Premium Dark Theme)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: AppTypography.h1.copyWith(color: AppColors.darkTextPrimary),
        displayMedium: AppTypography.h2.copyWith(color: AppColors.darkTextPrimary),
        displaySmall: AppTypography.h3.copyWith(color: AppColors.darkTextPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkTextSecondary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
        labelLarge: AppTypography.buttonText.copyWith(color: AppColors.darkTextPrimary),
        bodySmall: AppTypography.caption.copyWith(color: AppColors.darkMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h3.copyWith(color: AppColors.darkTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: AppElevation.button,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorderRadius,
          side: const BorderSide(color: AppColors.darkBorder, width: 1.0),
        ),
        elevation: AppElevation.card,
        margin: const EdgeInsets.all(AppSpacing.sm),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkDialog,
        elevation: AppElevation.dialog,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.dialogBorderRadius,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }

  /// Unified Light Theme Configuration (Premium Light Theme)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: AppTypography.h1.copyWith(color: AppColors.lightTextPrimary),
        displayMedium: AppTypography.h2.copyWith(color: AppColors.lightTextPrimary),
        displaySmall: AppTypography.h3.copyWith(color: AppColors.lightTextPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.lightTextSecondary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
        labelLarge: AppTypography.buttonText.copyWith(color: AppColors.lightTextPrimary),
        bodySmall: AppTypography.caption.copyWith(color: AppColors.lightTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h3.copyWith(color: AppColors.lightTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: AppElevation.button,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorderRadius,
          side: const BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
        elevation: AppElevation.card,
        margin: const EdgeInsets.all(AppSpacing.sm),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: AppElevation.dialog,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.dialogBorderRadius,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonBorderRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }

  /// Dynamic Theme token override builder from DB configs
  static ThemeData buildDynamicTheme(Map<String, dynamic> tokens) {
    try {
      final brandHex = (tokens['brand_color'] ?? '#5B5FEF').toString().replaceAll('#', '0xFF');
      final accentHex = (tokens['accent_color'] ?? '#8B5CF6').toString().replaceAll('#', '0xFF');
      final radius = double.tryParse((tokens['corner_radius'] ?? '12.0').toString()) ?? 12.0;

      final Color brandColor = Color(int.parse(brandHex));
      final Color accentColor = Color(int.parse(accentHex));

      return darkTheme.copyWith(
        colorScheme: darkTheme.colorScheme.copyWith(
          primary: brandColor,
          secondary: accentColor,
        ),
        cardTheme: darkTheme.cardTheme.copyWith(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radius)),
            side: const BorderSide(color: AppColors.darkBorder, width: 1.0),
          ),
        ),
      );
    } catch (_) {
      return darkTheme;
    }
  }
}
