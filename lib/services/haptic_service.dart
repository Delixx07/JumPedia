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

  /// Getaran ringan saat player melompat.
  static void jump() {
    if (!_enabled) return;
    _safe(HapticFeedback.lightImpact);
  }

  /// Getaran berat saat player mati / game over.
  static void death() {
    if (!_enabled) return;
    _safe(HapticFeedback.heavyImpact);
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
