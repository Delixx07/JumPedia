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
/// SpriteComponent untuk platform yang bisa diinjak player.
/// Mendukung 3 tipe: normal (statis), moving (bergerak), breakable (hancur).
/// Tampilan memakai sprite gambar dari assets/images/platforms/.

class Platform extends SpriteComponent with CollisionCallbacks {
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

  /// Frame animasi pecah untuk breakable.
  final List<Sprite> _breakFrames = [];

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

  /// Pilih nama file varian lebar terdekat (120 / 160 / 180).
  static String _widthVariant(double width) {
    if (width <= 140) return '120';
    if (width <= 170) return '160';
    return '180';
  }

  @override
  FutureOr<void> onLoad() async {
    final variant = _widthVariant(size.x);

    try {
      switch (type) {
        case PlatformType.normal:
          sprite = await Sprite.load(
              'platforms/platform_normal/platform_normal_$variant.png');
          break;
        case PlatformType.moving:
          sprite = await Sprite.load(
              'platforms/platform_moving/platform_moving_$variant.png');
          break;
        case PlatformType.breakable:
          // Tampilan awal: sprite breakable utuh (varian lebar).
          sprite = await Sprite.load(
              'platforms/platform_breakable/platform_breakable_$variant.png');
          // Frame animasi pecah (dimuat dari subfolder animation/).
          for (final i in const [0, 1, 2, 3, 5]) {
            _breakFrames.add(await Sprite.load(
                'platforms/platform_breakable/animation/platform_breakable_break_$i.png'));
          }
          break;
      }
    } catch (e) {
      AppLogger.warning('Sprite platform tidak ditemukan: $e');
    }

    // Hitbox tipis di permukaan ATAS platform — tempat player mendarat.
    // Tidak setinggi sprite agar fisika landing terasa pas (player bounce
    // saat menyentuh rumput/permukaan, bukan badan tanah di bawah).
    add(RectangleHitbox(
      size: Vector2(size.x, size.y * 0.5),
      position: Vector2(0, 0),
    ));
  }

  @override
  void render(Canvas canvas) {
    // Saat sprite belum selesai dimuat (atau gagal), JANGAN biarkan
    // SpriteComponent melempar assertion 'sprite != null'. Gambar fallback
    // sederhana (kapsul hijau/abu) sampai sprite siap.
    if (sprite == null) {
      final paint = Paint()
        ..color = switch (type) {
          PlatformType.normal => const Color(0xFF8BC34A),
          PlatformType.moving => const Color(0xFF90A4AE),
          PlatformType.breakable => const Color(0xFFFF9800),
        };
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.x, size.y),
          const Radius.circular(6),
        ),
        paint,
      );
      return;
    }
    super.render(canvas);
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
  /// Memainkan animasi frame pecah lalu menghapus platform.
  void breakPlatform() {
    if (type != PlatformType.breakable || _isBroken) return;
    _isBroken = true;
    AppLogger.game('Platform breakable hancur di posisi $position');

    // Mainkan frame pecah berurutan (~70ms per frame), lalu hapus.
    const frameDuration = Duration(milliseconds: 70);
    for (var i = 0; i < _breakFrames.length; i++) {
      Future.delayed(frameDuration * (i + 1), () {
        if (!isMounted) return;
        sprite = _breakFrames[i];
      });
    }
    Future.delayed(frameDuration * (_breakFrames.length + 1), () {
      if (isMounted) removeFromParent();
    });
  }
}
