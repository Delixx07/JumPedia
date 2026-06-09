import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../core/utils/logger.dart';
import '../world/game_world.dart';

/// ═══════════════════════════════════════
/// OBSTACLE COMPONENT — JumPedia
/// ═══════════════════════════════════════
/// Rintangan berupa robot "AI" — melambangkan ketergantungan pada AI yang
/// membuat orang malas berpikir. Menyentuhnya mengurangi HP player.
/// Jika player memiliki shield, obstacle tidak memberikan damage.
/// Tampil sebagai animasi float 7-frame.

class Obstacle extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameReference<GameWorld> {
  /// Apakah obstacle sudah memberikan damage (mencegah double-hit).
  bool _hasHit = false;

  /// Jumlah frame animasi float (obstacle_ai_float_1..7).
  static const int _frameCount = 7;

  /// Lebar/tinggi obstacle (kotak). Dipakai juga oleh logika spawn di
  /// GameWorld untuk menghitung tumpang tindih.
  static const double kSize = 42;

  Obstacle({
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(kSize, kSize),
          anchor: Anchor.center,
        );

  @override
  FutureOr<void> onLoad() async {
    try {
      final frames = <Sprite>[];
      // Frame dimulai dari 1 (obstacle_ai_float_1..7).
      for (var i = 1; i <= _frameCount; i++) {
        frames.add(await Sprite.load('obstacle/animation/obstacle_ai_float_$i.png'));
      }
      animation = SpriteAnimation.spriteList(frames, stepTime: 0.1);
    } catch (e) {
      AppLogger.warning('Animasi obstacle tidak ditemukan: $e');
      // Fallback: sprite statis tunggal agar obstacle tetap tampil.
      try {
        final still = await Sprite.load('obstacle/obstacle_ai.png');
        animation = SpriteAnimation.spriteList([still], stepTime: 1);
      } catch (_) {
        // biarkan; tidak crash
      }
    }
    add(RectangleHitbox());
  }

  /// ═══════════════════════════════════════
  /// ON HIT PLAYER
  /// ═══════════════════════════════════════
  /// Dipanggil saat player menabrak obstacle tanpa shield.
  /// Mengurangi HP player sebanyak 1 via hpProvider.
  void onHitPlayer(GameWorld gameWorld) {
    if (_hasHit) return;
    _hasHit = true;

    // Kurangi HP via game world (yang meneruskan ke hpProvider)
    gameWorld.reducePlayerHp();
    AppLogger.game('💥 Player terkena obstacle AI! HP berkurang.');

    // Hapus obstacle setelah hit
    removeFromParent();
  }
}
