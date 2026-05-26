import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';

/// ═══════════════════════════════════════
/// HP PROVIDER — JumPedia
/// ═══════════════════════════════════════
/// StateNotifierProvider untuk HP (Health Points) player.
/// HP = 0 berarti game over.

/// StateNotifier untuk mengelola HP player.
class HpNotifier extends StateNotifier<int> {
  HpNotifier() : super(AppConstants.initialHp);

  /// Kurangi HP sebanyak 1.
  /// Dipanggil saat player menabrak obstacle tanpa shield.
  void reduceHp() {
    if (state > 0) {
      state = state - 1;
    }
  }

  /// Tambah HP sebanyak [amount] (untuk power-up di masa depan).
  /// HP tidak bisa melebihi maxHp.
  void addHp(int amount) {
    state = (state + amount).clamp(0, AppConstants.maxHp);
  }

  /// Reset HP ke nilai awal.
  /// Dipanggil saat memulai game baru.
  void resetHp() {
    state = AppConstants.initialHp;
  }

  /// Getter: apakah game over (HP = 0).
  bool get isGameOver => state <= 0;
}

/// Provider global untuk HP player.
/// Gunakan ref.watch(hpProvider) untuk menampilkan HP di HUD.
/// Gunakan ref.read(hpProvider.notifier).reduceHp() saat terkena obstacle.
final hpProvider = StateNotifierProvider<HpNotifier, int>((ref) {
  return HpNotifier();
});

/// Provider turunan: apakah game over.
/// Gunakan ref.watch(isGameOverProvider) untuk memantau status game over.
final isGameOverProvider = Provider<bool>((ref) {
  final hp = ref.watch(hpProvider);
  return hp <= 0;
});
