import 'dart:async';
import 'dart:math';
import 'dart:ui';

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

  /// Bola Dunia — memberikan shield atau speed boost selama 5 detik.
  globe,
}

/// ═══════════════════════════════════════
/// COLLECTIBLE COMPONENT — JumPedia
/// ═══════════════════════════════════════
/// Objek yang bisa dikumpulkan player untuk mendapat poin atau boost.
/// Buku: +10 poin | Globe: shield/speed boost 5 detik.

class Collectible extends SpriteComponent
    with CollisionCallbacks, HasGameReference<GameWorld> {
  /// Tipe collectible.
  final CollectibleType type;

  /// Apakah sudah dikumpulkan (mencegah double-collect).
  bool _collected = false;

  /// Animasi hover: offset vertikal.
  double _hoverOffset = 0;
  double _hoverTime = 0;

  // Path relatif terhadap prefix 'assets/collectibles/'
  static final _bookAssets = [
    'book.png',
    'pencil.png',
  ];
  static const _globeAsset = 'globe.png';
  static final _rng = Random();

  // Custom Images cache agar Flame load dari assets/collectibles/ bukan assets/images/
  static final _collectiblesImages = Images(prefix: 'assets/collectibles/');

  Collectible({
    required Vector2 position,
    required this.type,
  }) : super(
          position: position,
          size: Vector2(40, 40),
          anchor: Anchor.center,
        );

  @override
  FutureOr<void> onLoad() async {
    final path = switch (type) {
      CollectibleType.book => _bookAssets[_rng.nextInt(_bookAssets.length)],
      CollectibleType.globe => _globeAsset,
    };

    try {
      sprite = await Sprite.load(path, images: _collectiblesImages);
    } catch (e) {
      AppLogger.warning('Sprite collectible tidak ditemukan ($path): $e');
    }
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _hoverTime += dt * 3;
    _hoverOffset = 3 * sin(_hoverTime);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(0, _hoverOffset);
    super.render(canvas);
    canvas.restore();
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
        // Tambah poin via scoreProvider
        gameWorld.addScore(AppConstants.bookPoints);
        AppLogger.game('📚 Buku dikumpulkan! +${AppConstants.bookPoints} poin');
        break;

      case CollectibleType.globe:
        // Aktifkan shield atau speed boost
        gameWorld.activatePlayerBoost();
        AppLogger.game('🌍 Globe dikumpulkan! Boost aktif!');
        break;
    }

    // Hapus dari game world
    removeFromParent();
  }
}
