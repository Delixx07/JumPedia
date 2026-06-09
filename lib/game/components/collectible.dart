import 'dart:async';

import 'package:flame/cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../world/game_world.dart';

/// ═══════════════════════════════════════
/// COLLECTIBLE TYPES
/// ═══════════════════════════════════════
enum CollectibleType {
  /// Buku — memberikan +10 poin saat dikumpulkan.
  book,

  /// Bola Dunia — memberikan shield selama 5 detik.
  globe,
}

/// ═══════════════════════════════════════
/// COLLECTIBLE COMPONENT — JumPedia
/// ═══════════════════════════════════════
/// Objek yang bisa dikumpulkan player. Tampil sebagai animasi "float"
/// 8-frame (book_float_0..7 / globe_float_0..7) agar terlihat hidup.
/// Buku: +10 poin | Globe: shield 5 detik.

class Collectible extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameReference<GameWorld> {
  /// Tipe collectible.
  final CollectibleType type;

  /// Apakah sudah dikumpulkan (mencegah double-collect).
  bool _collected = false;

  // Custom Images cache agar Flame load dari assets/collectibles/.
  static final _collectiblesImages = Images(prefix: 'assets/collectibles/');

  /// Lebar/tinggi sprite collectible. Dipakai juga oleh logika spawn di
  /// GameWorld untuk menghindari obstacle yang menimpa collectible.
  static const double kSize = 40;

  /// Jumlah frame animasi float.
  static const int _frameCount = 8;

  Collectible({
    required Vector2 position,
    required this.type,
  }) : super(
          position: position,
          size: Vector2(kSize, kSize),
          anchor: Anchor.center,
        );

  @override
  FutureOr<void> onLoad() async {
    final folder = type == CollectibleType.book ? 'book' : 'globe';
    final prefix = type == CollectibleType.book ? 'book_float' : 'globe_float';

    try {
      final frames = <Sprite>[];
      for (var i = 0; i < _frameCount; i++) {
        frames.add(await Sprite.load(
          '$folder/animation/${prefix}_$i.png',
          images: _collectiblesImages,
        ));
      }
      animation = SpriteAnimation.spriteList(
        frames,
        stepTime: 0.1, // ~1.25 detik per loop, gerak float lembut
      );
    } catch (e) {
      AppLogger.warning('Animasi collectible tidak ditemukan ($folder): $e');
      // Fallback: sprite statis tunggal agar item tetap tampil.
      try {
        final still =
            await Sprite.load('$folder/$folder.png', images: _collectiblesImages);
        animation = SpriteAnimation.spriteList([still], stepTime: 1);
      } catch (_) {
        // biarkan kosong; tidak crash
      }
    }

    add(CircleHitbox());
  }

  /// ═══════════════════════════════════════
  /// ON COLLECT
  /// ═══════════════════════════════════════
  /// Dipanggil saat player menyentuh collectible.
  void onCollect(GameWorld gameWorld) {
    if (_collected) return;
    _collected = true;

    switch (type) {
      case CollectibleType.book:
        gameWorld.addScore(AppConstants.bookPoints);
        AppLogger.game('📚 Buku dikumpulkan! +${AppConstants.bookPoints} poin');
        break;

      case CollectibleType.globe:
        gameWorld.activatePlayerBoost();
        AppLogger.game('🌍 Globe dikumpulkan! Shield aktif!');
        break;
    }

    removeFromParent();
  }
}
