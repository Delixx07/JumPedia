import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ═══════════════════════════════════════
/// SCORE PROVIDER — JumPedia
/// ═══════════════════════════════════════
/// StateNotifierProvider untuk skor real-time dalam game.
/// Digunakan oleh HUD overlay dan game components.

/// StateNotifier untuk mengelola skor game.
class ScoreNotifier extends StateNotifier<int> {
  ScoreNotifier() : super(0);

  /// Tambah poin ke skor saat ini.
  /// Dipanggil saat player mengumpulkan collectible atau naik ketinggian.
  void addPoints(int points) {
    state = state + points;
  }

  /// Reset skor ke 0.
  /// Dipanggil saat memulai game baru.
  void resetScore() {
    state = 0;
  }

  /// Getter untuk skor saat ini (convenience).
  int get currentScore => state;
}

/// Provider global untuk skor game.
/// Gunakan ref.watch(scoreProvider) di widget untuk real-time update.
/// Gunakan ref.read(scoreProvider.notifier) untuk memanggil method.
final scoreProvider = StateNotifierProvider<ScoreNotifier, int>((ref) {
  return ScoreNotifier();
});
