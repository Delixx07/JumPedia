// ═══════════════════════════════════════
// APP CONSTANTS — JumPedia
// ═══════════════════════════════════════
// Berisi semua konstanta game: skor, kecepatan, fisika, dan threshold.

class AppConstants {
  AppConstants._(); // Prevent instantiation

  // ─── Game Physics ─────────────────────
  /// Gravitasi yang diterapkan ke player setiap frame (pixel/detik²).
  static const double gravity = 980.0;

  /// Kekuatan lompatan player saat menyentuh platform (pixel/detik).
  static const double jumpForce = -600.0;

  /// Kecepatan horizontal player saat bergerak kiri/kanan (pixel/detik).
  static const double playerMoveSpeed = 300.0;

  /// Kecepatan scroll kamera ke atas (baseline, pixel/detik).
  static const double cameraScrollSpeed = 100.0;

  // ─── Platform Settings ────────────────
  /// Jarak vertikal rata-rata antar platform (pixel).
  static const double platformSpacing = 100.0;

  /// Lebar platform default (pixel).
  static const double platformWidth = 80.0;

  /// Tinggi platform default (pixel).
  static const double platformHeight = 15.0;

  /// Kecepatan platform bergerak (tipe moving) (pixel/detik).
  static const double movingPlatformSpeed = 80.0;

  /// Jumlah platform awal yang di-spawn saat game dimulai.
  static const int initialPlatformCount = 15;

  // ─── Player Settings ──────────────────
  /// HP awal player.
  static const int initialHp = 3;

  /// HP maksimum player.
  static const int maxHp = 5;

  /// Ukuran sprite player (pixel).
  static const double playerWidth = 40.0;
  static const double playerHeight = 50.0;

  // ─── Scoring ──────────────────────────
  /// Poin yang didapat saat mengambil buku.
  static const int bookPoints = 10;

  /// Poin yang didapat per unit ketinggian.
  static const double pointsPerHeight = 0.1;

  /// Selisih skor antar checkpoint fun fact.
  /// Setiap kali skor pemain naik kelipatan nilai ini, fun fact baru
  /// di-trigger (mis. di skor 100, 200, 300, ...). Dibuat agak besar
  /// supaya checkpoint tidak terlalu sering dan reward terasa berarti.
  static const int funFactScoreInterval = 100;

  // ─── Boost Settings ───────────────────
  /// Durasi shield/speed boost dari globe collectible (detik).
  static const double boostDuration = 5.0;

  /// Multiplier kecepatan saat speed boost aktif.
  static const double speedBoostMultiplier = 1.5;

  // ─── Leaderboard ──────────────────────
  /// Jumlah skor teratas yang ditampilkan di leaderboard.
  static const int leaderboardLimit = 10;

  // ─── Collectible / Obstacle Spawn ─────
  /// Probabilitas spawn collectible di atas platform (0.0 - 1.0).
  static const double collectibleSpawnChance = 0.3;

  /// Probabilitas spawn obstacle di antara platform (0.0 - 1.0).
  static const double obstacleSpawnChance = 0.15;

  // ─── Accelerometer ────────────────────
  /// Sensitivitas accelerometer untuk kontrol tilt.
  static const double accelerometerSensitivity = 15.0;
}
