import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// QuickSplit Design System — Claude Warm aesthetic
class AppColors {
  // Surfaces
  static const Color bg = Color(0xFFF7F5F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF0EDE8);
  static const Color border = Color(0xFFE8E3DB);
  static const Color borderFocus = Color(0xFFBFB8AD);

  // Dark mode surfaces
  static const Color bgDark = Color(0xFF1A1917);
  static const Color surfaceDark = Color(0xFF242220);
  static const Color surfaceAlt2 = Color(0xFF2E2B28);
  static const Color borderDark = Color(0xFF3D3935);

  // Text
  static const Color textPrimary = Color(0xFF1A1917);
  static const Color textSecondary = Color(0xFF706C66);
  static const Color textMuted = Color(0xFFADA89F);

  // Text dark
  static const Color textPrimaryDark = Color(0xFFF0EDE8);
  static const Color textSecondaryDark = Color(0xFF9E9890);
  static const Color textMutedDark = Color(0xFF5C5852);

  // Accent — warm amber
  static const Color accent = Color(0xFFD97706);
  static const Color accentSubtle = Color(0xFFFEF3C7);

  // Semantic
  static const Color positive = Color(0xFF16A34A);
  static const Color positiveSubtle = Color(0xFFDCFCE7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSubtle = Color(0xFFFEE2E2);
}

class AppTheme {
  AppTheme._();

  // ── Person Colors — Warm, Distinct ─────────────────────────────
  static const List<Color> personColors = [
    Color(0xFFE85D3F), // Terracotta
    Color(0xFF3B82F6), // Blue
    Color(0xFF16A34A), // Green
    Color(0xFF9333EA), // Purple
    Color(0xFFEA580C), // Orange
    Color(0xFF0891B2), // Cyan
    Color(0xFFDB2777), // Pink
    Color(0xFF65A30D), // Lime
  ];

  static Color getPersonColor(int index) =>
      personColors[index % personColors.length];

  // ── Person Emoji Circles (for share text) ─────────────────────
  static const List<String> personEmojis = [
    '🟢', '🔵', '🟡', '🟣', '🟤', '🔴', '🟠', '🟪',
  ];

  static String getPersonEmoji(int index) =>
      personEmojis[index % personEmojis.length];

  // ── Amount Style Helper ────────────────────────────────────────
  /// Returns a JetBrains Mono text style for all ฿ amounts.
  static TextStyle amountStyle({
    double size = 16,
    FontWeight weight = FontWeight.w600,
    Color? color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  // ── Spacing ────────────────────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;

  // ── Radius ─────────────────────────────────────────────────────
  static const double radiusCard = 16.0;
  static const double radiusButton = 12.0;
  static const double radiusInput = 10.0;
  static const double radiusBottomSheet = 24.0;

  // ── Responsive Breakpoints ─────────────────────────────────────
  static const double compactWidth = 360.0;
  static const double defaultWidth = 390.0;
  static const double comfortableWidth = 412.0;
  static const double tabletWidth = 600.0;
  static const double desktopWidth = 1024.0;

  static double getHorizontalPadding(double width) {
    if (width >= tabletWidth) return 32.0;
    if (width >= comfortableWidth) return 20.0;
    if (width < compactWidth) return 12.0;
    return 16.0;
  }

  static double? getMaxContentWidth(double width) {
    if (width >= desktopWidth) return 480.0;
    if (width >= tabletWidth) return 480.0;
    return null;
  }

  // ── Floating Shadow ────────────────────────────────────────────
  static const BoxShadow floatingShadow = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  // ── Light Theme ────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        error: AppColors.danger,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          fontSize: 20,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          elevation: 0,
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          side: const BorderSide(color: AppColors.border),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderFocus, width: 2),
        ),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 15,
          color: AppColors.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      textTheme: _buildTextTheme(dark: false),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusBottomSheet),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        dragHandleSize: Size(40, 4),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.accent.withValues(alpha: 0.2),
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accent.withValues(alpha: 0.12),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 10,
          elevation: 3,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        error: AppColors.danger,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          fontSize: 20,
          color: AppColors.textPrimaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          elevation: 0,
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          side: const BorderSide(color: AppColors.borderDark),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderFocus, width: 2),
        ),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 15,
          color: AppColors.textMutedDark,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      textTheme: _buildTextTheme(dark: true),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF484848),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusBottomSheet),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.borderDark,
        dragHandleSize: Size(40, 4),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.accent.withValues(alpha: 0.25),
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accent.withValues(alpha: 0.15),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 10,
          elevation: 3,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
    );
  }

  static TextTheme _buildTextTheme({required bool dark}) {
    final primary = dark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final secondary =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return TextTheme(
      displayLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 32,
        color: primary,
      ),
      headlineLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 24,
        color: primary,
      ),
      headlineMedium: GoogleFonts.dmSerifDisplay(
        fontSize: 20,
        color: primary,
      ),
      headlineSmall: GoogleFonts.dmSerifDisplay(
        fontSize: 18,
        color: primary,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: secondary,
        letterSpacing: 0.8,
      ),
    );
  }
}
