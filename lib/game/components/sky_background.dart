import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════
/// SKY BACKGROUND — JumPedia
/// ═══════════════════════════════════════
/// Background gradient langit + awan parallax. Render sebagai komponen
/// paling dulu (priority rendah) supaya selalu di belakang platform,
/// collectible, obstacle, dan player.
///
/// Posisi background DIKUNCI ke (0,0) — tidak ikut digeser oleh camera
/// scroll loop di [GameWorld.update]. Untuk efek parallax, [applyScroll]
/// dipanggil dari GameWorld setiap frame ketika kamera naik; awan
/// digeser lebih lambat dari scroll player → terasa jauh.

class SkyBackground extends PositionComponent {
  /// Daftar awan yang dirender sebagai blur ellipse putih.
  final List<_Cloud> _clouds = [];

  /// Offset vertikal awan (akumulasi parallax). Saat positive = awan
  /// digeser ke bawah → ilusi player naik ke atas langit.
  double _cloudOffsetY = 0;

  final Random _rng;

  /// [seed] dipakai untuk deterministic placement awan saat testing.
  SkyBackground({int? seed}) : _rng = Random(seed ?? 42) {
    priority = -10; // Selalu render paling dulu.
  }

  @override
  Future<void> onLoad() async {
    // Posisi terkunci di pojok kiri atas.
    position = Vector2.zero();
    size = Vector2(0, 0); // Akan di-set di onGameResize.
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    _ensureCloudsCover();
  }

  /// Generate awan random kalau pertama kali / saat resize.
  void _ensureCloudsCover() {
    if (_clouds.isNotEmpty) return;
    final w = size.x;
    final h = size.y;

    // Tutupi area ekstra di atas & di bawah (untuk parallax buffer).
    for (int i = 0; i < 14; i++) {
      _clouds.add(_Cloud(
        cx: _rng.nextDouble() * w,
        // Sebar dari -h/2 (di atas layar) sampai h (di bawah layar).
        cy: _rng.nextDouble() * (h * 1.5) - h * 0.25,
        radiusX: 40 + _rng.nextDouble() * 70,
        radiusY: 14 + _rng.nextDouble() * 18,
        alpha: 0.55 + _rng.nextDouble() * 0.35,
        speed: 0.4 + _rng.nextDouble() * 0.45, // Parallax factor.
      ));
    }
  }

  /// Dipanggil GameWorld setiap frame saat kamera naik.
  /// Awan ikut digeser ke bawah, tapi lebih lambat dari platform
  /// (per-cloud `speed` < 1) — menghasilkan parallax depth.
  void applyScroll(double scrollAmount) {
    _cloudOffsetY += scrollAmount;
    // Recycle awan yang sudah keluar layar bawah → respawn ke atas.
    final h = size.y;
    for (final c in _clouds) {
      final renderedY = c.cy + _cloudOffsetY * c.speed;
      if (renderedY > h + 50) {
        // Reset awan ke atas layar dengan posisi X baru.
        c.cy -= h + 100;
        c.cx = _rng.nextDouble() * size.x;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    if (w <= 0 || h <= 0) return;

    // ─── Gradient sky ──────────────────────
    final rect = Rect.fromLTWH(0, 0, w, h);
    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF2D6FB8), // deep sky
        Color(0xFF4A9CE0),
        Color(0xFFB8E1FF), // pale sky
      ],
      stops: [0.0, 0.55, 1.0],
    );
    canvas.drawRect(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );

    // ─── Awan blur parallax ────────────────
    final cloudPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (final c in _clouds) {
      cloudPaint.color = Colors.white.withValues(alpha: c.alpha);
      final cy = c.cy + _cloudOffsetY * c.speed;
      // Skip awan yang jauh keluar layar untuk hemat draw call.
      if (cy < -80 || cy > h + 80) continue;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.cx, cy),
          width: c.radiusX * 2,
          height: c.radiusY * 2,
        ),
        cloudPaint,
      );
    }
  }
}

/// Awan tunggal — posisi dasar (cx, cy) + ukuran + faktor parallax.
class _Cloud {
  double cx;
  double cy;
  final double radiusX;
  final double radiusY;
  final double alpha;
  final double speed; // 0..1, semakin kecil = semakin jauh.

  _Cloud({
    required this.cx,
    required this.cy,
    required this.radiusX,
    required this.radiusY,
    required this.alpha,
    required this.speed,
  });
}
