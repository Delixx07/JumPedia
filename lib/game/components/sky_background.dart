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

  /// Daftar bintang untuk di angkasa.
  final List<_Star> _stars = [];

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
    _ensureStarsCover();
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

  void _ensureStarsCover() {
    if (_stars.isNotEmpty) return;
    for (int i = 0; i < 40; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble() * size.x,
        y: _rng.nextDouble() * size.y,
        size: 0.5 + _rng.nextDouble() * 1.5,
        brightness: 0.3 + _rng.nextDouble() * 0.7,
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

    // ─── Dynamic Gradient sky ──────────────────
    // Berubah dari Biru (Day) -> Navy (Atmosphere) -> Hitam (Space)
    // Milestone tinggi (pixel): 0 -> 4000 (Atmosphere) -> 10000 (Space)
    final altitude = _cloudOffsetY;
    
    // Faktor transisi 0.0 (day) -> 1.0 (space)
    final spaceFactor = (altitude / 10000).clamp(0.0, 1.0);
    
    final Color topColor = Color.lerp(
      const Color(0xFF2D6FB8), // Deep sky
      const Color(0xFF02050A), // Near black space
      spaceFactor,
    )!;
    
    final Color midColor = Color.lerp(
      const Color(0xFF4A9CE0),
      const Color(0xFF0B1424), // Dark navy
      spaceFactor,
    )!;

    final Color bottomColor = Color.lerp(
      const Color(0xFFB8E1FF), // Pale sky
      const Color(0xFF1A2B44), // Space horizon
      spaceFactor,
    )!;

    final rect = Rect.fromLTWH(0, 0, w, h);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, midColor, bottomColor],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );

    // ─── Tanah (Ground) ────────────────────
    // Hanya terlihat di awal permainan (altitude rendah)
    // Kita buat tanah muncul sedikit di bawah platform pertama (sekitar h-100)
    if (altitude < h) {
      final groundY = (h - 100) + altitude;
      final groundPaint = Paint()..color = const Color(0xFF5D4037); // Brown
      canvas.drawRect(Rect.fromLTWH(0, groundY, w, h), groundPaint);
      
      // Rumput di atas tanah
      final grassPaint = Paint()..color = const Color(0xFF4CAF50); // Green
      canvas.drawRect(Rect.fromLTWH(0, groundY, w, 20), grassPaint);
    }

    // ─── Bintang (Stars) ──────────────────
    // Muncul perlahan saat memasuki angkasa
    if (spaceFactor > 0.2) {
      final starAlpha = ((spaceFactor - 0.2) / 0.8).clamp(0.0, 1.0);
      final starPaint = Paint();
      for (final s in _stars) {
        starPaint.color = Colors.white.withValues(alpha: s.brightness * starAlpha);
        canvas.drawCircle(Offset(s.x, s.y), s.size, starPaint);
      }
    }

    // ─── Earth Curve (High Altitude) ───────
    // Terlihat saat altitude > 12000
    if (altitude > 12000) {
      final earthFactor = ((altitude - 12000) / 8000).clamp(0.0, 1.0);
      final curvePaint = Paint()
        ..color = const Color(0xFF1E88E5).withValues(alpha: earthFactor * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      
      // Menggambar busur besar di bawah untuk simulasi lengkungan bumi
      canvas.drawCircle(
        Offset(w / 2, h + (2000 * (1 - earthFactor)) + 1500),
        2500,
        curvePaint,
      );
      
      // Glow atmosfer bumi
      final glowPaint = Paint()
        ..color = const Color(0xFFBBDEFB).withValues(alpha: earthFactor * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      
      canvas.drawCircle(
        Offset(w / 2, h + (2000 * (1 - earthFactor)) + 1500),
        2510,
        glowPaint,
      );
    }

    // ─── Awan blur parallax ────────────────
    // Pudar saat semakin tinggi (masuk angkasa hampa)
    final cloudAlphaFactor = (1.0 - (altitude / 7000)).clamp(0.0, 1.0);
    if (cloudAlphaFactor > 0) {
      final cloudPaint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      for (final c in _clouds) {
        cloudPaint.color = Colors.white.withValues(alpha: c.alpha * cloudAlphaFactor);
        final cy = c.cy + _cloudOffsetY * c.speed;
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

class _Star {
  final double x;
  final double y;
  final double size;
  final double brightness;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
  });
}
