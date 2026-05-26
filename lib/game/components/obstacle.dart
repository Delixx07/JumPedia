import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../core/utils/logger.dart';
import '../world/game_world.dart';

/// ═══════════════════════════════════════
/// OBSTACLE COMPONENT — JumPedia
/// ═══════════════════════════════════════
/// Rintangan berupa sampah plastik yang mengurangi HP player.
/// Jika player memiliki shield, obstacle tidak memberikan damage.

class Obstacle extends SpriteComponent
    with CollisionCallbacks, HasGameReference<GameWorld> {
  /// Apakah obstacle sudah memberikan damage (mencegah double-hit).
  bool _hasHit = false;

  // Path relatif terhadap prefix 'assets/images/' (Flame default)
  static const _assets = [
    'obstacle/kantong_plastik.png',
    'obstacle/botol_plastik.png',
    'obstacle/botol_kaleng.png',
  ];
  static final _rng = Random();

  Obstacle({
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(42, 42),
          anchor: Anchor.center,
        );

  @override
  FutureOr<void> onLoad() async {
    try {
      sprite = await Sprite.load(_assets[_rng.nextInt(_assets.length)]);
    } catch (e) {
      AppLogger.warning('Sprite obstacle tidak ditemukan: $e');
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
    AppLogger.game('💥 Player terkena obstacle! HP berkurang.');

    // Hapus obstacle setelah hit
    removeFromParent();
  }
}
