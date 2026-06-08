import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

/// ═══════════════════════════════════════
/// PLATFORM TYPES
/// ═══════════════════════════════════════
enum PlatformType {
  /// Platform statis — tidak bergerak.
  normal,

  /// Platform bergerak — bergerak horizontal, berbalik di tepi.
  moving,

  /// Platform rapuh — hancur setelah 1 kali diinjak.
  breakable,
}

/// ═══════════════════════════════════════
/// PLATFORM COMPONENT — JumPedia
/// ═══════════════════════════════════════
/// PositionComponent untuk platform yang bisa diinjak player.
/// Mendukung 3 tipe: normal (statis), moving (bergerak), breakable (hancur).

class Platform extends PositionComponent with CollisionCallbacks {
  /// Tipe platform.
  final PlatformType type;

  /// Kecepatan horizontal (hanya untuk tipe moving).
  final double _moveSpeed;

  /// Arah gerak horizontal: 1 = kanan, -1 = kiri.
  double _moveDirection = 1;

  /// Batas kiri dan kanan gerak platform moving.
  final double _screenWidth;

  /// Apakah platform sudah diinjak (untuk breakable).
  bool _isBroken = false;

  /// Paint berdasarkan tipe platform.
  late final Paint _paint;

  Platform({
    required Vector2 position,
    required this.type,
    double width = AppConstants.platformWidth,
    double screenWidth = 400,
  })  : _moveSpeed = type == PlatformType.moving
            ? AppConstants.movingPlatformSpeed
            : 0,
        _screenWidth = screenWidth,
        super(
          position: position,
          size: Vector2(width, AppConstants.platformHeight),
        );

  @override
  FutureOr<void> onLoad() {
    // Set warna berdasarkan tipe platform
    _paint = Paint()
      ..color = switch (type) {
        PlatformType.normal => const Color(0xFF8BC34A), // Hijau
        PlatformType.moving => const Color(0xFF2196F3), // Biru
        PlatformType.breakable => const Color(0xFFFF9800), // Oranye
      };

    // Tambah hitbox untuk collision detection
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    if (_isBroken) return; // Jangan render jika sudah hancur

    // Render platform sebagai rounded rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(4),
      ),
      _paint,
    );

    // Indikator visual untuk platform moving (garis-garis)
    if (type == PlatformType.moving) {
      final arrowPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(size.x * 0.3, size.y / 2),
        Offset(size.x * 0.7, size.y / 2),
        arrowPaint,
      );
    }

    // Indikator visual untuk platform breakable (retak)
    if (type == PlatformType.breakable) {
      final crackPaint = Paint()
        ..color = const Color(0x88000000)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(size.x * 0.3, 0),
        Offset(size.x * 0.5, size.y),
        crackPaint,
      );
      canvas.drawLine(
        Offset(size.x * 0.6, 0),
        Offset(size.x * 0.4, size.y),
        crackPaint,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // ─── Moving Platform Logic ───────────
    if (type == PlatformType.moving && !_isBroken) {
      position.x += _moveSpeed * _moveDirection * dt;

      // Berbalik arah di tepi layar
      if (position.x <= 0) {
        _moveDirection = 1;
      } else if (position.x + size.x >= _screenWidth) {
        _moveDirection = -1;
      }
    }
  }

  /// ═══════════════════════════════════════
  /// BREAK PLATFORM
  /// ═══════════════════════════════════════
  /// Dipanggil saat player menginjak platform breakable.
  /// Platform akan hancur dan dihapus dari parent setelah delay singkat.
  void breakPlatform() {
    if (type != PlatformType.breakable || _isBroken) return;

    _isBroken = true;
    AppLogger.game('Platform breakable hancur di posisi $position');

    // Hapus dari parent setelah delay animasi singkat
    Future.delayed(const Duration(milliseconds: 200), () {
      if (isMounted) removeFromParent();
    });
  }

}
