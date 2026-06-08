import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../providers/fun_fact_provider.dart';
import '../../providers/hp_provider.dart';
import '../../providers/score_provider.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';
import '../components/collectible.dart';
import '../components/obstacle.dart';
import '../components/platform.dart' as game_platform;
import '../components/player.dart';
import '../components/sky_background.dart';

/// ═══════════════════════════════════════
/// GAME WORLD — JumPedia
/// ═══════════════════════════════════════
/// FlameGame utama yang mengelola seluruh game loop:
/// - Spawn platform, collectible, dan obstacle
/// - Scroll kamera ke atas mengikuti player
/// - Track ketinggian dan trigger fun facts setiap 500 unit
/// - Pantau HP dan trigger game over

class GameWorld extends FlameGame with HasCollisionDetection, TapCallbacks {
  /// Jarak horizontal aman (pixel) yang harus dijaga obstacle dari platform
  /// & collectible, agar player yang mendarat tidak langsung tertabrak.
  static const double _obstacleClearance = 24;

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

  /// Background langit + awan parallax — dikunci ke (0,0), tidak ikut
  /// digeser oleh camera scroll loop.
  late SkyBackground _sky;

  /// Random number generator untuk spawning.
  final Random _rng = Random();

  /// Posisi Y tertinggi yang pernah dicapai player (untuk skor ketinggian).
  double _highestY = 0;

  /// Total poin ketinggian yang sudah ditambahkan ke score (terpisah dari poin collectible).
  int _heightScoreAdded = 0;

  /// Skor saat checkpoint fun fact terakhir dipicu. Fun fact berikutnya
  /// muncul ketika skor mencapai nilai ini + funFactScoreInterval.
  int _lastFunFactScore = 0;

  /// Apakah game sudah selesai (mencegah double game over).
  bool _isGameOver = false;

  /// Apakah game sedang di-pause untuk fun fact.
  bool _isPausedForFact = false;

  /// Platform teratas saat ini (untuk spawning platform baru).
  double _topPlatformY = 0;

  /// Apakah player sudah pernah mendarat / lompat dari platform.
  /// Selama belum pernah, jika player jatuh di luar layar dia tidak mati —
  /// melainkan di-respawn ke posisi awal. Ini menutup bug di mana player
  /// kadang spawn sambil "menabrak" platform pertama tanpa sempat bounce,
  /// lalu langsung jatuh & game over tanpa input apa pun.
  bool _hasEverLanded = false;

  GameWorld({
    required this.ref,
    required this.onGameOver,
    required this.showOverlay,
    required this.hideOverlay,
  });

  @override
  FutureOr<void> onLoad() async {
    AppLogger.game('GameWorld loading...');

    // ─── Preload efek suara ──────────────
    AudioService.preload();

    // ─── Background langit ───────────────
    // Add paling dulu agar priority -10 selalu render di belakang.
    _sky = SkyBackground();
    add(_sky);

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

    // Prefetch fakta checkpoint pertama, TAPI ditunda beberapa detik supaya
    // panggilan AI tidak menyendat inisialisasi & frame awal game. Checkpoint
    // pertama (skor 500) baru tercapai jauh setelah ini, jadi fakta tetap siap.
    Future.delayed(const Duration(seconds: 3), () {
      if (isMounted) _prefetchFact(1);
    });

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

      // Geser semua komponen ke bawah (simulasi kamera naik).
      // KECUALI background — dia tetap di (0,0) & menangani parallax
      // sendiri lewat applyScroll() (awan jalan lebih lambat).
      for (final component in children) {
        if (component is PositionComponent && component is! SkyBackground) {
          component.position.y += scrollAmount;
        }
      }
      _sky.applyScroll(scrollAmount);

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
    // Tampilkan fun fact setiap kelipatan funFactScoreInterval poin
    // (mis. di skor 40, 80, 120, ...). Berbasis skor — bukan tinggi —
    // supaya checkpoint lebih jarang dan reward terasa berarti.
    final currentScore = ref.read(scoreProvider);
    final nextFactScore =
        _lastFunFactScore + AppConstants.funFactScoreInterval;

    if (currentScore >= nextFactScore) {
      _lastFunFactScore = nextFactScore;
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
    // Platform tempat mendarat sebelumnya (gap obstacle berada di antara
    // platform lama & yang baru ini).
    final prevPlatformY = _topPlatformY;

    _topPlatformY -= AppConstants.platformSpacing +
        _rng.nextDouble() * 30; // Variasi jarak

    final platformWidth =
        AppConstants.platformWidth + _rng.nextDouble() * 40; // 80-120 px
    final x =
        _rng.nextDouble() * (size.x - platformWidth - 20) + 10;

    final platform = game_platform.Platform(
      position: Vector2(x, _topPlatformY),
      type: _randomPlatformType(),
      width: platformWidth,
      screenWidth: size.x,
    );

    add(platform);

    // Spawn collectible di atas platform (30% chance). Simpan posisinya agar
    // obstacle tidak ditempatkan menimpa collectible.
    double? collectibleX;
    if (_rng.nextDouble() < AppConstants.collectibleSpawnChance) {
      collectibleX = x + platformWidth / 2 - Collectible.kSize / 2;
      _spawnCollectible(collectibleX, _topPlatformY - 40);
    }

    // Spawn obstacle DI GAP antara platform baru & platform sebelumnya.
    // Dipilih agar tidak menutupi kedua platform maupun collectible, sehingga
    // selalu bisa dihindari dengan gerak kiri/kanan.
    if (_rng.nextDouble() < AppConstants.obstacleSpawnChance) {
      final gapMidY = (prevPlatformY + _topPlatformY) / 2;
      final obstacleX = _pickObstacleX(
        platformLeft: x,
        platformWidth: platformWidth,
        collectibleX: collectibleX,
      );
      if (obstacleX != null) {
        // gapMidY adalah titik tengah; _spawnObstacle ingin sudut atas.
        _spawnObstacle(obstacleX, gapMidY - Obstacle.kSize / 2);
      }
    }
  }

  /// Pilih tipe platform: 60% normal, 25% moving, 15% breakable.
  game_platform.PlatformType _randomPlatformType() {
    final roll = _rng.nextDouble();
    if (roll < 0.60) return game_platform.PlatformType.normal;
    if (roll < 0.85) return game_platform.PlatformType.moving;
    return game_platform.PlatformType.breakable;
  }

  /// Cari koordinat X (sudut kiri obstacle) di dalam gap yang TIDAK menutupi
  /// platform yang baru di-spawn maupun collectible di atasnya. Menjaga jarak
  /// aman ([_obstacleClearance]) supaya player yang mendarat di platform tidak
  /// langsung kena. Mengembalikan null jika tidak ada ruang yang aman.
  double? _pickObstacleX({
    required double platformLeft,
    required double platformWidth,
    double? collectibleX,
  }) {
    const obstacleSize = Obstacle.kSize;
    const clearance = _obstacleClearance;
    final maxX = size.x - obstacleSize;
    if (maxX <= 0) return null;

    // Zona terlarang: rentang X (untuk sudut kiri obstacle) yang akan membuat
    // obstacle bertumpang tindih dengan platform / collectible + clearance.
    final forbidden = <(double, double)>[];

    // Platform (+ clearance di kedua sisi).
    forbidden.add((
      platformLeft - obstacleSize - clearance,
      platformLeft + platformWidth + clearance,
    ));

    // Collectible (+ clearance).
    if (collectibleX != null) {
      forbidden.add((
        collectibleX - obstacleSize - clearance,
        collectibleX + Collectible.kSize + clearance,
      ));
    }

    // Coba beberapa kandidat acak; pakai yang pertama di luar zona terlarang.
    for (int attempt = 0; attempt < 12; attempt++) {
      final candidate = _rng.nextDouble() * maxX;
      final clashes = forbidden.any((zone) =>
          candidate >= zone.$1 && candidate <= zone.$2);
      if (!clashes) return candidate;
    }
    return null; // gap terlalu penuh — lewati obstacle kali ini
  }

  /// ═══════════════════════════════════════
  /// SPAWN COLLECTIBLE
  /// ═══════════════════════════════════════
  /// [leftX]/[topY] adalah sudut kiri-atas; dikonversi ke titik tengah karena
  /// Collectible memakai Anchor.center.
  void _spawnCollectible(double leftX, double topY) {
    final type = _rng.nextDouble() < 0.7
        ? CollectibleType.book // 70% chance buku
        : CollectibleType.globe; // 30% chance globe

    final collectible = Collectible(
      position: Vector2(
        leftX + Collectible.kSize / 2,
        topY + Collectible.kSize / 2,
      ),
      type: type,
    );

    add(collectible);
  }

  /// ═══════════════════════════════════════
  /// SPAWN OBSTACLE
  /// ═══════════════════════════════════════
  /// [leftX]/[topY] adalah sudut kiri-atas; dikonversi ke titik tengah karena
  /// Obstacle memakai Anchor.center.
  void _spawnObstacle(double leftX, double topY) {
    final obstacle = Obstacle(
      position: Vector2(
        leftX + Obstacle.kSize / 2,
        topY + Obstacle.kSize / 2,
      ),
    );
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
      if (component is PositionComponent &&
          component is! Player &&
          component is! SkyBackground) {
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
  /// Pause game dan tampilkan fun fact overlay setiap kelipatan skor checkpoint.
  /// Menaikkan counter checkpoint agar overlay men-generate fakta AI baru.
  void _triggerFunFact() {
    _isPausedForFact = true;
    ref.read(factCheckpointProvider.notifier).next();
    showOverlay('funFact');
    AppLogger.game('🎓 Fun fact triggered at score: $_lastFunFactScore');
  }

  /// Resume game setelah fun fact ditutup.
  void resumeFromFunFact() {
    _isPausedForFact = false;
    hideOverlay('funFact');
    AppLogger.game('Game resumed after fun fact');

    // Prefetch fakta untuk checkpoint BERIKUTNYA di latar belakang, supaya
    // saat checkpoint itu tercapai fakta sudah siap (tanpa jeda loading).
    final current = ref.read(factCheckpointProvider);
    _prefetchFact(current + 1);
  }

  /// Hangatkan cache [aiFunFactProvider] untuk nomor [checkpoint] tertentu.
  /// Memicu generate AI lebih awal; hasilnya tersimpan di cache Riverpod
  /// sampai overlay men-watch key yang sama.
  void _prefetchFact(int checkpoint) {
    ref.read(aiFunFactProvider(checkpoint).future).then((_) {
      AppLogger.game('🔮 Prefetched fun fact for checkpoint $checkpoint');
    }).catchError((Object e) {
      // Diamkan — kalau prefetch gagal, overlay akan coba lagi saat dibuka.
      AppLogger.warning('Prefetch fun fact gagal: $e', tag: 'Gemini');
    });
  }

  /// ═══════════════════════════════════════
  /// GAME OVER HANDLING
  /// ═══════════════════════════════════════
  void _handleGameOver() {
    _isGameOver = true;
    AudioService.playDeath();
    HapticService.death();
    AppLogger.game('💀 GAME OVER! Final score: ${ref.read(scoreProvider)}');
    onGameOver();
  }

  /// Dipanggil saat player jatuh dari layar.
  void onPlayerFellOff() {
    if (_isGameOver) return;

    // Grace period: kalau player belum pernah mendarat sekalipun di
    // platform manapun, anggap dia "masih loncat" — respawn ke posisi
    // awal saja, jangan kurangi HP. Ini menutup bug "spawn → langsung
    // game over" tanpa input.
    if (!_hasEverLanded) {
      _respawnPlayerAtStart();
      AppLogger.game('Player fell before first landing — respawned safely');
      return;
    }

    // Set HP ke 0 untuk trigger game over.
    final currentHp = ref.read(hpProvider);
    for (int i = 0; i < currentHp; i++) {
      ref.read(hpProvider.notifier).reduceHp();
    }
  }

  /// Tandai bahwa player sudah pernah mendarat di platform.
  /// Dipanggil dari Player.onCollisionStart saat bounce pertama berhasil.
  void markPlayerLanded() {
    _hasEverLanded = true;
  }

  /// Kembalikan player ke titik spawn awal (di atas landing platform).
  /// Dipakai saat fall sebelum landing pertama.
  void _respawnPlayerAtStart() {
    player.velocity.setValues(0, 0);
    player.position.setValues(
      size.x / 2 - player.size.x / 2,
      size.y - 200,
    );
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
  /// PUBLIC INPUT API (UI controls)
  /// ═══════════════════════════════════════
  /// Dipanggil dari on-screen button overlay (mobile) maupun keyboard
  /// listener di GameScreen (desktop).
  void playerMoveLeft() => player.moveLeft();
  void playerMoveRight() => player.moveRight();
  void playerStop() => player.stopHorizontal();

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
