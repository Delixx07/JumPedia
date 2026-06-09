import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';

/// ═══════════════════════════════════════
/// APP THEME — JumPedia
/// ═══════════════════════════════════════
/// ThemeData terpusat: tipografi (Poppins heading + Nunito body),
/// skema warna, dan tema komponen (input, snackbar, dialog, bottom sheet).
///
/// Font dipakai LANGSUNG sebagai family Flutter (di-bundle di assets/fonts &
/// didaftarkan di pubspec) — TIDAK lewat google_fonts. Ini mencegah error
/// runtime "weight not found" / fetch internet yang sempat membuat app crash
/// di perangkat fisik.

class AppTheme {
  AppTheme._();

  static const String _heading = 'Poppins';
  static const String _body = 'Nunito';

  static ThemeData get light {
    const cs = ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.bgMid,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSurface: AppColors.textHi,
    );

    // Body default Nunito; heading override ke Poppins.
    final textTheme = const TextTheme().apply(
      fontFamily: _body,
      bodyColor: AppColors.textHi,
      displayColor: AppColors.textHi,
    ).copyWith(
      displayLarge: const TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w900,
          color: AppColors.textHi),
      headlineLarge: const TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w800,
          color: AppColors.textHi),
      headlineMedium: const TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w800,
          color: AppColors.textHi),
      titleLarge: const TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w700,
          color: AppColors.textHi),
      titleMedium: const TextStyle(
          fontFamily: _heading,
          fontWeight: FontWeight.w600,
          color: AppColors.textHi),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.scaffold,
      fontFamily: _body,
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
        contentTextStyle: const TextStyle(
            fontFamily: _body,
            color: Colors.white,
            fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppDimens.brMd),
      ),

      // ─── Dialog ───────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgMid,
        shape: RoundedRectangleBorder(borderRadius: AppDimens.brLg),
        titleTextStyle: const TextStyle(
            fontFamily: _heading,
            color: AppColors.textHi,
            fontSize: 18,
            fontWeight: FontWeight.w700),
        contentTextStyle: const TextStyle(
            fontFamily: _body, color: AppColors.textLo),
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
