import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single Source of Truth for the entire Cross-Platform Design System.
/// Consumed identically across Android, iOS, Web, and Admin.
class AppColors {
  // Premium Dark Theme Layers
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkTertiary = Color(0xFF1C2128);
  static const Color darkContainer = Color(0xFF20262E);
  static const Color darkElevated = Color(0xFF252C36);
  static const Color darkCard = Color(0xFF1E2430);
  static const Color darkDialog = Color(0xFF202833);
  static const Color darkBottomSheet = Color(0xFF202833);
  static const Color darkNavigation = Color(0xFF111827);
  static const Color darkDivider = Color(0xFF2B3442);
  static const Color darkBorder = Color(0xFF323C4A);
  static const Color darkOverlay = Color(0x10FFFFFF); // rgba(255,255,255,0.06)
  static const Color darkGlass = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // Primary Brand Colors
  static const Color primary = Color(0xFF5B5FEF);
  static const Color primaryLight = Color(0xFF7C82FF);
  static const Color primaryDark = Color(0xFF4548C4);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFA855F7);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color teal = Color(0xFF14B8A6);

  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  // Text Colors (Dark Mode)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC5CBD6);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textCaption = Color(0xFF7A8599);
  static const Color textDisabled = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFF111827);

  // Icon Colors
  static const Color iconNormal = Color(0xFFC5CBD6);
  static const Color iconSelected = Color(0xFF5B5FEF);
  static const Color iconAccent = Color(0xFF8B5CF6);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;
  static const double spacing80 = 80.0;
  static const double spacing96 = 96.0;

  // Responsive margins helper
  static double getResponsiveMargin(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return spacing32;
    if (width > 840) return xxl;
    return lg;
  }
}

class AppRadius {
  static const double small = 12.0;
  static const double medium = 16.0;
  static const double large = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double circular = 999.0;

  static BorderRadius get cardBorderRadius => BorderRadius.circular(xl); // 24px Card Radius
  static BorderRadius get buttonBorderRadius => BorderRadius.circular(medium); // 16px Button Radius
  static BorderRadius get dialogBorderRadius => BorderRadius.circular(xxl); // 32px Dialog Radius
}

class AppTypography {
  static TextStyle get display => GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle get headline => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  static TextStyle get title => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get subtitle => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get smallBody => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );
}

class AppAnimation {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);

  static Curve get defaultCurve => Curves.fastOutSlowIn;
}

class AppShadows {
  static List<BoxShadow> get lightCardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get darkCardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppGradients {
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
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
  static const double card = 0.0; // Flat layout with border borders preferred
  static const double dialog = 12.0;
  static const double button = 0.0;
}
