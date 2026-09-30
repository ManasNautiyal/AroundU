import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AroundU Design System — Premium Black & White Theme
/// Inspired by Bumble/Hinge UI polish with a monochrome palette.
class AppTheme {
  AppTheme._();

  // ── Color Palette ────────────────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offBlack = Color(0xFF0A0A0A);
  static const Color darkGray = Color(0xFF1A1A1A);
  static const Color mediumGray = Color(0xFF2A2A2A);
  static const Color subtleGray = Color(0xFF3A3A3A);
  static const Color borderGray = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF999999);
  static const Color textTertiary = Color(0xFF666666);
  static const Color shimmer = Color(0xFF1F1F1F);
  static const Color accentWhite = Color(0xFFF5F5F5);

  // ── Color Scheme ─────────────────────────────────────────────────
  static const ColorScheme colorScheme = ColorScheme.dark(
    primary: white,
    onPrimary: black,
    secondary: accentWhite,
    onSecondary: black,
    surface: offBlack,
    onSurface: white,
    surfaceContainerHighest: mediumGray,
    outline: borderGray,
    outlineVariant: subtleGray,
    error: Color(0xFFFF6B6B),
    onError: white,
  );

  // ── Text Theme (Google Fonts — Inter) ────────────────────────────
  static TextTheme get _textTheme {
    return GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.2, color: white),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: white),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: white),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: white),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: white),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: white),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: white),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: white),
        titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: white),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: white),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45, color: white),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, color: textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: white),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2, color: textSecondary),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.2, color: textSecondary),
      ),
    );
  }

  // ── Full ThemeData ────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      scaffoldBackgroundColor: black,

      // ── App Bar ────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: white, size: 22),
        titleTextStyle: GoogleFonts.inter(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      // ── Card ───────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: darkGray,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderGray, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Bottom Navigation Bar (premium pill-style) ────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: offBlack,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: white,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: black, size: 22);
          }
          return const IconThemeData(color: textSecondary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: white,
              letterSpacing: 0.2,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecondary,
            letterSpacing: 0.2,
          );
        }),
      ),

      // ── Filled Button ─────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: white,
          foregroundColor: black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Elevated Button ───────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: white,
          foregroundColor: black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Outlined Button ───────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: white,
          side: const BorderSide(color: borderGray, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Text Button ───────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: white,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input Decoration ──────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkGray,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderGray, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderGray, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: white.withValues(alpha: 0.6), width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.0),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: textTertiary, fontSize: 14),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // ── Bottom Sheet ──────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: offBlack,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: false,
      ),

      // ── Dialog ────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: darkGray,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      // ── Snackbar ──────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: white,
        contentTextStyle: GoogleFonts.inter(
          color: black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // ── Chip ──────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: darkGray,
        selectedColor: white,
        disabledColor: darkGray,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderGray, width: 0.8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ── Divider ───────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: borderGray,
        thickness: 0.5,
        space: 0,
      ),

      // ── Switch ────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return white;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return white.withValues(alpha: 0.3);
          return borderGray;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Slider ────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: white,
        inactiveTrackColor: borderGray,
        thumbColor: white,
        overlayColor: white.withValues(alpha: 0.1),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        trackHeight: 3.5,
        showValueIndicator: ShowValueIndicator.never,
      ),

      // ── Progress Indicator ────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: white,
      ),

      // ── Tab Bar ───────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: white,
        unselectedLabelColor: textSecondary,
        indicatorColor: white,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Shared decoration helpers
class AppDecorations {
  AppDecorations._();

  /// Standard card container decoration
  static BoxDecoration card({double borderRadius = 20}) => BoxDecoration(
    color: AppTheme.darkGray,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: AppTheme.borderGray, width: 0.8),
  );

  /// Glassmorphic overlay
  static BoxDecoration glass({double opacity = 0.06}) => BoxDecoration(
    color: Colors.white.withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.08),
      width: 0.8,
    ),
  );

  /// Standard drag handle for bottom sheets
  static Widget dragHandle() => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 12, bottom: 20),
      height: 4,
      width: 40,
      decoration: BoxDecoration(
        color: AppTheme.subtleGray,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  /// Standard bottom sheet container decoration
  static BoxDecoration bottomSheet() => const BoxDecoration(
    color: AppTheme.offBlack,
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    border: Border(
      top: BorderSide(color: AppTheme.borderGray, width: 0.8),
    ),
  );
}
