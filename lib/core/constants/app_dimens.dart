import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ═══════════════════════════════════════
/// DESIGN TOKENS — JumPedia
/// ═══════════════════════════════════════
/// Sumber tunggal untuk spacing, radius, shadow, dan durasi animasi.
/// Tujuannya: tampilan konsisten & rapi di seluruh app ("deploy-ready").

class AppDimens {
  AppDimens._();

  // ─── Spacing (kelipatan 4) ────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Padding standar tepi layar.
  static const EdgeInsets screenPadding = EdgeInsets.all(xl);

  // ─── Radius ───────────────────────────
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusPill = 30;

  static BorderRadius get brSm => BorderRadius.circular(radiusSm);
  static BorderRadius get brMd => BorderRadius.circular(radiusMd);
  static BorderRadius get brLg => BorderRadius.circular(radiusLg);

  // ─── Elevation / shadow ───────────────
  /// Shadow lembut untuk kartu (flat tapi tetap berdimensi).
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.textHi.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Shadow tipis untuk elemen kecil (tombol, chip).
  static List<BoxShadow> shadowOf(Color color, {double alpha = 0.22}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  // ─── Durasi animasi ───────────────────
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 360);
}
