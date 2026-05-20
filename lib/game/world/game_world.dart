import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../providers/hp_provider.dart';
import '../../providers/score_provider.dart';
import '../components/collectible.dart';
import '../components/obstacle.dart';
import '../components/platform.dart' as game_platform;
import '../components/player.dart';

/// ═══════════════════════════════════════
/// GAME WORLD — SDG Eco-Jump
/// ═══════════════════════════════════════
/// FlameGame utama yang mengelola seluruh game loop:
/// - Spawn platform, collectible, dan obstacle
/// - Scroll kamera ke atas mengikuti player
/// - Track ketinggian dan trigger fun facts setiap 500 unit
/// - Pantau HP dan trigger game over

class GameWorld extends FlameGame with HasCollisionDetection, TapCallbacks {
  /// Reference ke Riverpod container untuk akses providers.
  final WidgetRef ref;

  /// Callback untuk navigasi ke game over screen.
  final VoidCallback onGameOver;

  /// Callback untuk menampilkan fun fact overlay.
  final Function(String overlayName) showOverlay;

  /// Callback untuk menyembunyikan overlay.
  final Function(String overlayName) hideOverlay;

  /// Player component.
  late Player player;

  /// Random number generator untuk spawning.
  final Random _rng = Random();

  /// Posisi Y tertinggi yang pernah dicapai player (untuk skor ketinggian).
  double _highestY = 0;

  /// Total poin ketinggian yang sudah ditambahkan ke score (terpisah dari poin collectible).
  int _heightScoreAdded = 0;

  /// Counter untuk interval fun fact (setiap 500 unit height).
  int _lastFunFactHeight = 0;

  /// Apakah game sudah selesai (mencegah double game over).
  bool _isGameOver = false;

  /// Apakah game sedang di-pause untuk fun fact.
  bool _isPausedForFact = false;

  /// Platform teratas saat ini (untuk spawning platform baru).
  double _topPlatformY = 0;

  GameWorld({
    required this.ref,
    required this.onGameOver,
    required this.showOverlay,
    required this.hideOverlay,
  });

  @override
  FutureOr<void> onLoad() async {
    AppLogger.game('GameWorld loading...');

    // ─── Spawn Platform Awal ─────────────
    // Spawn platform pertama tepat di bawah player sebagai landing pad
    final landingPlatform = game_platform.Platform(
      position: Vector2(size.x / 2 - 50, size.y - 100),
      type: game_platform.PlatformType.normal,
      width: 100,
      screenWidth: size.x,
    );
    add(landingPlatform);

    // Spawn platform-platform di atas
    _topPlatformY = size.y - 100;
    for (int i = 1; i < AppConstants.initialPlatformCount; i++) {
      _spawnPlatform();
    }

    // ─── Inisialisasi Player ─────────────
    player = Player();
    add(player);

    AppLogger.game('GameWorld loaded! ${AppConstants.initialPlatformCount} platforms spawned');
  }

  /// ═══════════════════════════════════════
  /// GAME LOOP UPDATE
  /// ═══════════════════════════════════════
  @override
  void update(double dt) {
    if (_isGameOver || _isPausedForFact) return;

    super.update(dt);

    // ─── Camera Scroll ───────────────────
    // Scroll kamera ke atas mengikuti player jika player naik
    // lebih tinggi dari tengah layar
    final playerMidY = player.position.y;
    final screenMidY = size.y * 0.4; // Player target di 40% atas layar

    if (playerMidY < screenMidY) {
      final scrollAmount = screenMidY - playerMidY;

      // Geser semua komponen ke bawah (simulasi kamera naik)
      for (final component in children) {
        if (component is PositionComponent) {
          component.position.y += scrollAmount;
        }
      }

      // Track ketinggian absolut dan posisi platform teratas
      _highestY += scrollAmount;
      _topPlatformY += scrollAmount;
    }

    // ─── Spawn Platform Baru ─────────────
    // Tambah platform baru di atas jika player naik
    while (_topPlatformY > -AppConstants.platformSpacing) {
      _spawnPlatform();
    }

    // ─── Hapus Komponen di Bawah Layar ───
    // Optimasi memori: hapus platform/collectible/obstacle yang sudah
    // jauh di bawah layar (tidak terlihat lagi)
    _cleanupOffscreenComponents();

    // ─── Skor Ketinggian ─────────────────
    // Tambah poin berdasarkan ketinggian yang dicapai.
    // Dilacak terpisah dari poin collectible agar tidak saling mengganggu.
    final heightScore = (_highestY * AppConstants.pointsPerHeight).toInt();
    if (heightScore > _heightScoreAdded) {
      ref.read(scoreProvider.notifier).addPoints(heightScore - _heightScoreAdded);
      _heightScoreAdded = heightScore;
    }

    // ─── Fun Fact Trigger ────────────────
    // Tampilkan fun fact setiap 500 unit height
    final currentHeight = _highestY.toInt();
    final nextFactHeight =
        (_lastFunFactHeight + AppConstants.funFactInterval.toInt());

    if (currentHeight >= nextFactHeight) {
      _lastFunFactHeight = nextFactHeight;
      _triggerFunFact();
    }

    // ─── Game Over Check ─────────────────
    final isGameOverFromHp = ref.read(isGameOverProvider);
    if (isGameOverFromHp && !_isGameOver) {
      _handleGameOver();
    }
  }

  /// ═══════════════════════════════════════
  /// SPAWN PLATFORM
  /// ═══════════════════════════════════════
  void _spawnPlatform() {
    _topPlatformY -= AppConstants.platformSpacing +
        _rng.nextDouble() * 30; // Variasi jarak

    final x = _rng.nextDouble() * (size.x - AppConstants.platformWidth - 20) + 10;

    final platform = game_platform.Platform.random(
      x: x,
      y: _topPlatformY,
      screenWidth: size.x,
      rng: _rng,
    );

    add(platform);

    // Spawn collectible di atas platform (30% chance)
    if (_rng.nextDouble() < AppConstants.collectibleSpawnChance) {
      _spawnCollectible(x + 25, _topPlatformY - 40);
    }

    // Spawn obstacle di antara platform (15% chance)
    if (_rng.nextDouble() < AppConstants.obstacleSpawnChance) {
      final obstacleX = _rng.nextDouble() * (size.x - 40);
      _spawnObstacle(obstacleX, _topPlatformY - 60);
    }
  }

  /// ═══════════════════════════════════════
  /// SPAWN COLLECTIBLE
  /// ═══════════════════════════════════════
  void _spawnCollectible(double x, double y) {
    final type = _rng.nextDouble() < 0.7
        ? CollectibleType.book // 70% chance buku
        : CollectibleType.globe; // 30% chance globe

    final collectible = Collectible(
      position: Vector2(x, y),
      type: type,
    );

    add(collectible);
  }

  /// ═══════════════════════════════════════
  /// SPAWN OBSTACLE
  /// ═══════════════════════════════════════
  void _spawnObstacle(double x, double y) {
    final obstacle = Obstacle(position: Vector2(x, y));
    add(obstacle);
  }

  /// ═══════════════════════════════════════
  /// CLEANUP OFFSCREEN COMPONENTS
  /// ═══════════════════════════════════════
  /// Hapus komponen yang sudah jauh di bawah layar untuk optimasi memori.
  void _cleanupOffscreenComponents() {
    final threshold = size.y + 200; // 200 pixel di bawah layar

    final toRemove = <PositionComponent>[];
    for (final component in children) {
      if (component is PositionComponent && component is! Player) {
        if (component.position.y > threshold) {
          toRemove.add(component);
        }
      }
    }

    for (final component in toRemove) {
      component.removeFromParent();
    }
  }

  /// ═══════════════════════════════════════
  /// FUN FACT TRIGGER
  /// ═══════════════════════════════════════
  /// Pause game dan tampilkan fun fact overlay setiap 500 unit ketinggian.
  void _triggerFunFact() {
    _isPausedForFact = true;
    showOverlay('funFact');
    AppLogger.game('🎓 Fun fact triggered at height: $_highestY');
  }

  /// Resume game setelah fun fact ditutup.
  void resumeFromFunFact() {
    _isPausedForFact = false;
    hideOverlay('funFact');
    AppLogger.game('Game resumed after fun fact');
  }

  /// ═══════════════════════════════════════
  /// GAME OVER HANDLING
  /// ═══════════════════════════════════════
  void _handleGameOver() {
    _isGameOver = true;
    AppLogger.game('💀 GAME OVER! Final score: ${ref.read(scoreProvider)}');
    onGameOver();
  }

  /// Dipanggil saat player jatuh dari layar.
  void onPlayerFellOff() {
    if (!_isGameOver) {
      // Set HP ke 0 untuk trigger game over
      final currentHp = ref.read(hpProvider);
      for (int i = 0; i < currentHp; i++) {
        ref.read(hpProvider.notifier).reduceHp();
      }
    }
  }

  /// ═══════════════════════════════════════
  /// PLAYER ACTIONS (dipanggil dari components)
  /// ═══════════════════════════════════════

  /// Tambah skor (dipanggil oleh Collectible).
  void addScore(int points) {
    ref.read(scoreProvider.notifier).addPoints(points);
  }

  /// Kurangi HP player (dipanggil oleh Obstacle).
  void reducePlayerHp() {
    ref.read(hpProvider.notifier).reduceHp();
    AppLogger.game('HP berkurang! Sisa: ${ref.read(hpProvider)}');
  }

  /// Aktifkan boost pada player (dipanggil oleh Collectible globe).
  void activatePlayerBoost() {
    // Randomly pilih shield atau speed boost
    if (_rng.nextBool()) {
      player.activateShield(AppConstants.boostDuration);
    } else {
      player.activateSpeedBoost(AppConstants.boostDuration);
    }
  }

  /// ═══════════════════════════════════════
  /// TAP CONTROLS
  /// ═══════════════════════════════════════
  /// Tap kiri layar = gerak kiri, tap kanan = gerak kanan.
  @override
  void onTapDown(TapDownEvent event) {
    final tapX = event.localPosition.x;
    if (tapX < size.x / 2) {
      player.moveLeft();
    } else {
      player.moveRight();
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    player.stopHorizontal();
  }
}
