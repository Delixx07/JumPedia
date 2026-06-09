import 'package:flutter/services.dart';

import '../core/utils/logger.dart';

/// ═══════════════════════════════════════
/// HAPTIC SERVICE — JumPedia
/// ═══════════════════════════════════════
/// Pembungkus tipis di atas HapticFeedback bawaan Flutter untuk getaran
/// saat lompat & mati. Bisa dimatikan via toggle di Settings.
class HapticService {
  HapticService._();

  /// Apakah getaran aktif. Diset dari [HapticEnabled] provider.
  static bool _enabled = true;

  static void setEnabled(bool enabled) => _enabled = enabled;

  static bool get isEnabled => _enabled;

  /// Getaran saat player melompat (medium agar lebih terasa dari sebelumnya).
  static void jump() {
    if (!_enabled) return;
    _safe(HapticFeedback.mediumImpact);
  }

  /// Getaran ringan saat mengambil collectible (buku/globe).
  static void collect() {
    if (!_enabled) return;
    _safe(HapticFeedback.selectionClick);
  }

  /// Getaran saat terkena obstacle (kehilangan HP).
  static void hit() {
    if (!_enabled) return;
    _safe(HapticFeedback.mediumImpact);
  }

  /// Getaran berat + pola ganda saat player mati / game over.
  static void death() {
    if (!_enabled) return;
    _safe(HapticFeedback.heavyImpact);
    // Dentuman kedua sesaat kemudian agar "mati" terasa lebih kuat.
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_enabled) _safe(HapticFeedback.heavyImpact);
    });
  }

  static void _safe(Future<void> Function() action) {
    try {
      action();
    } catch (e) {
      // Beberapa device/web tidak mendukung haptic — diamkan.
      AppLogger.warning('Haptic tidak didukung: $e', tag: 'Haptic');
    }
  }
}
