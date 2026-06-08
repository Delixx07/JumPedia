import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';

/// ═══════════════════════════════════════
/// APP THEME — JumPedia
/// ═══════════════════════════════════════
/// ThemeData terpusat: tipografi (Poppins heading + Nunito body),
/// skema warna, dan tema komponen (input, snackbar, dialog, bottom sheet,
/// nav bar) agar seluruh app konsisten tanpa styling manual berulang.

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const cs = ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.bgMid,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSurface: AppColors.textHi,
    );

    // Body pakai Nunito; heading pakai Poppins (di bawah).
    final baseText = GoogleFonts.nunitoTextTheme();
    final textTheme = baseText.copyWith(
      displayLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w900, color: AppColors.textHi),
      headlineLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w800, color: AppColors.textHi),
      headlineMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w800, color: AppColors.textHi),
      titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w700, color: AppColors.textHi),
      titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, color: AppColors.textHi),
    ).apply(
      bodyColor: AppColors.textHi,
      displayColor: AppColors.textHi,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.scaffold,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,

      // ─── Input fields ─────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgMid,
        hintStyle: const TextStyle(color: AppColors.textLo),
        labelStyle: const TextStyle(color: AppColors.primary),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.lg, vertical: AppDimens.md),
        border: OutlineInputBorder(
          borderRadius: AppDimens.brMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimens.brMd,
          borderSide: BorderSide(
              color: AppColors.textLo.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimens.brMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),

      // ─── SnackBar ─────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textHi,
        contentTextStyle: GoogleFonts.nunito(
            color: Colors.white, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppDimens.brMd),
      ),

      // ─── Dialog ───────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgMid,
        shape: RoundedRectangleBorder(borderRadius: AppDimens.brLg),
        titleTextStyle: GoogleFonts.poppins(
            color: AppColors.textHi,
            fontSize: 18,
            fontWeight: FontWeight.w700),
        contentTextStyle: GoogleFonts.nunito(color: AppColors.textLo),
      ),

      // ─── Bottom sheet ─────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgMid,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
        ),
      ),

      // ─── Icon ─────────────────────────
      iconTheme: const IconThemeData(color: AppColors.textHi),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }
}
