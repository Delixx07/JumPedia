import 'dart:developer' as developer;

/// ═══════════════════════════════════════
/// LOGGER UTILITY — SDG Eco-Jump
/// ═══════════════════════════════════════
/// Wrapper untuk logging yang bisa diaktifkan/nonaktifkan berdasarkan flavor.
/// Gunakan AppLogger alih-alih print() agar log bisa dikontrol.

class AppLogger {
  AppLogger._(); // Prevent instantiation

  /// Flag untuk mengaktifkan/menonaktifkan logging.
  /// Diatur oleh AppConfig berdasarkan flavor (dev/prod).
  static bool _enabled = true;

  /// Inisialisasi logger. Panggil di main().
  static void init({required bool enabled}) {
    _enabled = enabled;
  }

  /// Log pesan debug. Hanya muncul jika logging diaktifkan.
  static void debug(String message, {String tag = 'SDG-EcoJump'}) {
    if (!_enabled) return;
    developer.log(
      message,
      name: tag,
      time: DateTime.now(),
    );
  }

  /// Log informasi penting (selalu muncul, terlepas dari flag).
  static void info(String message, {String tag = 'SDG-EcoJump'}) {
    developer.log(
      '📘 $message',
      name: tag,
      time: DateTime.now(),
    );
  }

  /// Log warning.
  static void warning(String message, {String tag = 'SDG-EcoJump'}) {
    developer.log(
      '⚠️ $message',
      name: tag,
      time: DateTime.now(),
      level: 900, // Warning level
    );
  }

  /// Log error dengan optional stack trace.
  static void error(
    String message, {
    String tag = 'SDG-EcoJump',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      '❌ $message',
      name: tag,
      time: DateTime.now(),
      level: 1000, // Severe level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log khusus untuk operasi Firestore CRUD.
  static void firestore(String operation, String path, {String? detail}) {
    if (!_enabled) return;
    developer.log(
      '🔥 [$operation] $path${detail != null ? ' → $detail' : ''}',
      name: 'Firestore',
      time: DateTime.now(),
    );
  }

  /// Log khusus untuk game events.
  static void game(String message) {
    if (!_enabled) return;
    developer.log(
      '🎮 $message',
      name: 'GameEngine',
      time: DateTime.now(),
    );
  }
}
