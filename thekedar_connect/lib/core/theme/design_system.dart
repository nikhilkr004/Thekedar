import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single Source of Truth for the entire Cross-Platform Design System.
/// Consumed identically across Android, iOS, Web, and Admin.
class AppColors {
  // Premium Dark Theme Tokens
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF1E2430);
  static const Color darkDialog = Color(0xFF202833);
  static const Color darkBorder = Color(0x10FFFFFF); // rgba(255,255,255,0.06)
  
  static const Color primary = Color(0xFF5B5FEF);
  static const Color accent = Color(0xFF8B5CF6);
  static const Color secondary = Color(0xFF3B82F6);
  
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFC5CBD6);
  static const Color darkMuted = Color(0xFF9CA3AF);

  // Premium Light Theme Tokens
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Responsive margins helper
  static double getResponsiveMargin(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return xl;
    if (width > 840) return lg;
    return md;
  }
}

class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double round = 999.0;

  static BorderRadius get cardBorderRadius => BorderRadius.circular(md);
  static BorderRadius get buttonBorderRadius => BorderRadius.circular(md);
  static BorderRadius get dialogBorderRadius => BorderRadius.circular(lg);
}

class AppTypography {
  static TextStyle get h1 => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      );

  static TextStyle get h3 => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
      );

  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );
}

class AppAnimation {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static Curve get defaultCurve => Curves.easeInOutCubic;
}

class AppShadows {
  static List<BoxShadow> get lightCardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get darkCardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppGradients {
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [AppColors.primary, AppColors.accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get darkSurfaceGradient => const LinearGradient(
        colors: [AppColors.darkSurface, AppColors.darkCard],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}

class AppIcons {
  static const IconData handyman = Icons.handyman_outlined;
  static const IconData dashboard = Icons.dashboard_outlined;
  static const IconData leads = Icons.business_center_outlined;
  static const IconData wallet = Icons.account_balance_wallet_outlined;
  static const IconData profile = Icons.person_outline;
  static const IconData notifications = Icons.notifications_none;
  static const IconData verify = Icons.verified_user_outlined;
  static const IconData settings = Icons.settings_outlined;
  static const IconData check = Icons.check_circle_outline;
}

class AppElevation {
  static const double card = 2.0;
  static const double dialog = 8.0;
  static const double button = 1.0;
}
