import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../world/game_world.dart';
import 'collectible.dart';
import 'obstacle.dart';
import 'platform.dart' as game_platform;

/// ═══════════════════════════════════════
/// PLAYER COMPONENT — JumPedia
/// ═══════════════════════════════════════
/// SpriteComponent untuk karakter pemain.
/// Mendukung kontrol tap (kiri/kanan) dan accelerometer (tilt).
/// Collision callbacks untuk interaksi dengan platform, collectible, dan obstacle.

enum PlayerState { idle, jumping, landed, hurt, collecting, shielded }

class Player extends SpriteComponent
    with CollisionCallbacks, KeyboardHandler, HasGameReference<GameWorld> {
  /// Kecepatan player (x = horizontal, y = vertikal).
  Vector2 velocity = Vector2.zero();

  /// Apakah player sedang berdiri di atas platform.
  bool isOnGround = false;

  /// Apakah player memiliki shield aktif (kebal dari obstacle).
  bool hasShield = false;

  /// Timer untuk speed boost (detik tersisa).
  double speedBoostTimer = 0.0;

  /// Arah horizontal: -1 = kiri, 0 = diam, 1 = kanan.
  int _horizontalDirection = 0;

  /// State karakter untuk memilih sprite.
  PlayerState _state = PlayerState.idle;
  double _stateTimer = 0.0;

  Sprite? _idleSprite;
  Sprite? _jumpSprite;
  Sprite? _landSprite;
  Sprite? _hurtSprite;
  Sprite? _collectSprite;
  Sprite? _shieldSprite;

  final Paint _shieldPaint = Paint()
    ..color = const Color(0x5500BCD4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  Player()
      : super(
          size: Vector2(
            AppConstants.playerWidth,
            AppConstants.playerHeight,
          ),
        );

  @override
  FutureOr<void> onLoad() async {
    // Posisi awal: tengah bawah layar, cukup tinggi di atas landing
    // platform (yang ada di y = size.y - 100) supaya gravity sempat
    // memberikan velocity.y > 0 sebelum tabrakan terjadi — syarat
    // bounce di onCollisionStart.
    position = Vector2(
      game.size.x / 2 - size.x / 2,
      game.size.y - 200,
    );

    // Tambah hitbox untuk collision detection
    add(RectangleHitbox());

    // Load sprite asset karakter dari folder lumi.
    // Flame prepends 'assets/images/' secara otomatis, jadi path dimulai dari dalam folder itu.
    try {
      _idleSprite = await Sprite.load('lumi/lumi_idle.png');
      _jumpSprite = await Sprite.load('lumi/lumi_jump.png');
      _landSprite = await Sprite.load('lumi/lumi_land.png');
      _hurtSprite = await Sprite.load('lumi/lumi_hurt.png');
      _collectSprite = await Sprite.load('lumi/lumi_collect.png');
      _shieldSprite = await Sprite.load('lumi/lumi_shield.png');
      sprite = _idleSprite;
    } catch (e) {
      // Jika sprite tidak ada, fallback ke rectangle hijau di render()
      AppLogger.warning('Sprite lumi tidak ditemukan, pakai fallback: $e');
    }

    AppLogger.game('Player loaded at position: $position');
  }

  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      super.render(canvas);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.x, size.y),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xFF4CAF50),
      );
    }

    if (hasShield) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x * 0.8,
        _shieldPaint,
      );
    }
  }

  void _setState(PlayerState state, [double duration = 0]) {
    if (_state == state && duration <= 0 && _stateTimer <= 0) {
      return;
    }

    _state = state;
    _stateTimer = duration;

    switch (state) {
      case PlayerState.idle:
        sprite = _idleSprite;
        break;
      case PlayerState.jumping:
        sprite = _jumpSprite;
        break;
      case PlayerState.landed:
        sprite = _landSprite;
        break;
      case PlayerState.hurt:
        sprite = _hurtSprite;
        break;
      case PlayerState.collecting:
        sprite = _collectSprite;
        break;
      case PlayerState.shielded:
        sprite = _shieldSprite;
        break;
    }
  }

  void _resolveState() {
    if (hasShield) {
      _setState(PlayerState.shielded);
      return;
    }

    if (_state == PlayerState.hurt || _state == PlayerState.collecting) {
      if (_stateTimer > 0) {
        return;
      }
    }

    if (velocity.y < -10) {
      _setState(PlayerState.jumping);
    } else if (velocity.y > 10 && !isOnGround) {
      _setState(PlayerState.landed);
    } else {
      _setState(PlayerState.idle);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_stateTimer > 0) {
      _stateTimer -= dt;
      if (_stateTimer <= 0) {
        _stateTimer = 0;
      }
    }

    _resolveState();

    // ─── Gravity ─────────────────────────
    // Gravity selalu aktif; player jatuh ke bawah
    velocity.y += AppConstants.gravity * dt;

    // ─── Horizontal Movement ─────────────
    final moveSpeed = speedBoostTimer > 0
        ? AppConstants.playerMoveSpeed * AppConstants.speedBoostMultiplier
        : AppConstants.playerMoveSpeed;

    velocity.x = _horizontalDirection * moveSpeed;

    // ─── Apply Velocity ──────────────────
    position += velocity * dt;

    // ─── Screen Wrapping ─────────────────
    // Player muncul di sisi berlawanan jika keluar layar
    if (position.x < -size.x) {
      position.x = game.size.x;
    } else if (position.x > game.size.x) {
      position.x = -size.x;
    }

    // ─── Speed Boost Timer ───────────────
    if (speedBoostTimer > 0) {
      speedBoostTimer -= dt;
      if (speedBoostTimer <= 0) {
        speedBoostTimer = 0;
        AppLogger.game('Speed boost ended');
      }
    }

    // ─── Game Over Check ─────────────────
    // Jika player jatuh terlalu jauh di bawah layar
    if (position.y > game.size.y + 200) {
      game.onPlayerFellOff();
    }
  }

  /// ═══════════════════════════════════════
  /// TAP CONTROLS
  /// ═══════════════════════════════════════
  /// Dipanggil dari GameWorld tap detector.
  /// Tap kiri layar = gerak kiri, tap kanan = gerak kanan.
  void moveLeft() {
    _horizontalDirection = -1;
  }

  void moveRight() {
    _horizontalDirection = 1;
  }

  void stopHorizontal() {
    _horizontalDirection = 0;
  }

  /// ═══════════════════════════════════════
  /// ACCELEROMETER CONTROL
  /// ═══════════════════════════════════════
  /// Dipanggil dari GameWorld saat ada data accelerometer.
  /// [tilt] negatif = tilt kiri, positif = tilt kanan.
  void applyAccelerometer(double tilt) {
    _horizontalDirection = 0;
    velocity.x = -tilt * AppConstants.accelerometerSensitivity;
  }

  /// ═══════════════════════════════════════
  /// JUMP
  /// ═══════════════════════════════════════
  /// Player melompat otomatis saat menyentuh platform.
  void jump() {
    velocity.y = AppConstants.jumpForce;
    isOnGround = false;
    _setState(PlayerState.jumping);
    AppLogger.game('Player jumped! Velocity: ${velocity.y}');
  }

  /// ═══════════════════════════════════════
  /// ACTIVATE SHIELD
  /// ═══════════════════════════════════════
  void activateShield(double duration) {
    hasShield = true;
    _setState(PlayerState.shielded);
    Future.delayed(Duration(seconds: duration.toInt()), () {
      if (!isMounted) return;
      hasShield = false;
      _resolveState();
      AppLogger.game('Shield deactivated');
    });
    AppLogger.game('Shield activated for ${duration}s');
  }

  /// ═══════════════════════════════════════
  /// ACTIVATE SPEED BOOST
  /// ═══════════════════════════════════════
  void activateSpeedBoost(double duration) {
    speedBoostTimer = duration;
    AppLogger.game('Speed boost activated for ${duration}s');
  }

  /// ═══════════════════════════════════════
  /// COLLISION HANDLING
  /// ═══════════════════════════════════════
  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    // ─── Platform Collision ──────────────
    if (other is game_platform.Platform) {
      // Hanya bounce jika player sedang jatuh (velocity.y > 0)
      // dan player berada di atas platform
      if (velocity.y > 0) {
        // Cek apakah player jatuh dari atas platform
        final playerBottom = position.y + size.y;
        final platformTop = other.position.y;

        if (playerBottom <= platformTop + 20) {
          isOnGround = true;
          // Lompat otomatis saat menyentuh platform
          jump();
          // Tandai sudah pernah landing — setelah ini, fall akan
          // mengurangi HP seperti biasa.
          game.markPlayerLanded();

          // Handle platform breakable
          if (other.type == game_platform.PlatformType.breakable) {
            other.breakPlatform();
          }
        }
      }
    }

    // ─── Collectible Collision ───────────
    if (other is Collectible) {
      _setState(PlayerState.collecting, 0.4);
      other.onCollect(game);
    }

    // ─── Obstacle Collision ─────────────
    if (other is Obstacle) {
      if (!hasShield) {
        _setState(PlayerState.hurt, 0.5);
        other.onHitPlayer(game);
      } else {
        // Shield menyerap damage
        AppLogger.game('Shield absorbed obstacle hit!');
        other.removeFromParent();
      }
    }
  }

  /// ═══════════════════════════════════════
  /// KEYBOARD HANDLER (untuk debug di desktop)
  /// ═══════════════════════════════════════
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _horizontalDirection = 0;

    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      _horizontalDirection = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      _horizontalDirection = 1;
    }

    return true;
  }
}
