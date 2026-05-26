import 'package:flutter/material.dart';

// ═══════════════════════════════════════
// APP COLORS — JumPedia (Pastel Blue palette)
// ═══════════════════════════════════════
// Sumber kebenaran tunggal untuk warna brand JumPedia.
// Light mode penuh: background biru muda pastel, text navy gelap,
// accent biru solid untuk CTA, amber gold untuk highlight.

class AppColors {
  AppColors._();

  // ─── Primary palette ──────────────────
  /// Biru solid — accent utama untuk CTA, ikon aktif, tombol primary.
  static const Color primary = Color(0xFF1E88E5);

  /// Biru muda — pendamping primary (gradient, hover state).
  static const Color primaryLight = Color(0xFF6FB7FF);

  /// Biru lebih gelap — untuk text accent, border kuat.
  static const Color primaryDark = Color(0xFF0B5FBF);

  /// Accent kedua — amber gold untuk best score, badge, warning.
  static const Color accent = Color(0xFFFFC107);

  /// Warning kuning (= accent untuk konsistensi).
  static const Color warn = Color(0xFFFFC107);

  // ─── Backgrounds ──────────────────────
  /// Background utama scaffold — biru muda pastel.
  static const Color scaffold = Color(0xFFCDE9FF);

  /// Background atas hero gradient (sama dengan scaffold agar konsisten).
  static const Color bgTop = Color(0xFFE4F2FF);

  /// Mid surface — putih bersih untuk card.
  static const Color bgMid = Color(0xFFFFFFFF);

  /// Background bawah gradient (sedikit lebih dalam dari bgTop).
  static const Color bgBottom = Color(0xFFCDE9FF);

  // ─── Text ─────────────────────────────
  static const Color textHi = Color(0xFF0B2A4A); // Navy gelap untuk heading
  static const Color textLo = Color(0xFF4F7AA5); // Biru muted untuk sub-text
  static const Color textMuted = Color(0x804F7AA5);

  // ─── Status ───────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);

  // ─── Borders / dividers ──────────────
  static const Color border = Color(0x331C4E8C);

  // ─── Gradients ────────────────────────
  /// Gradient utama untuk background hero (Home, Splash, etc).
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  /// Gradient untuk tombol primary & accent surface (biru → biru muda).
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryLight, primary],
  );

  /// Gradient lembut untuk surface card.
  static LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.95),
      Colors.white.withValues(alpha: 0.75),
    ],
  );

  /// Gradient untuk kartu reward / fun fact (biru muda → biru).
  static const LinearGradient accentCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );
}
