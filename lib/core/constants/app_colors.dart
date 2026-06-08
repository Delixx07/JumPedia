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

  // ─── Flat surfaces (no gradients) ─────
  // Desain flat: tidak ada gradiasi. "Gradient" di bawah dipertahankan
  // sebagai alias agar widget lama tetap kompatibel, tapi tiap definisi
  // memakai satu warna solid (dua stop identik) sehingga tampak rata.

  /// Background utama scaffold — biru muda pastel solid.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [scaffold, scaffold],
  );

  /// Surface biru solid untuk CTA / accent surface.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primary],
  );

  /// Surface card — putih solid.
  static const LinearGradient cardGradient = LinearGradient(
    colors: [bgMid, bgMid],
  );

  /// Surface kartu reward / fun fact — biru solid.
  static const LinearGradient accentCardGradient = LinearGradient(
    colors: [primary, primary],
  );
}
