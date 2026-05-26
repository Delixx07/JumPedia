import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fun_fact_model.dart';
import '../services/fun_fact_service.dart';

/// ═══════════════════════════════════════
/// FUN FACT PROVIDER — JumPedia
/// ═══════════════════════════════════════
/// Provider untuk data fun facts dari Firestore.
/// Digunakan oleh fun_fact_overlay.dart saat player mencapai milestone.

/// Provider untuk instance FunFactService.
final funFactServiceProvider = Provider<FunFactService>((ref) {
  return FunFactService();
});

/// FutureProvider: mengambil semua fun facts dari Firestore.
/// Data di-cache oleh Riverpod setelah pertama kali diambil.
final allFunFactsProvider = FutureProvider<List<FunFactModel>>((ref) async {
  final service = ref.watch(funFactServiceProvider);
  return service.getAllFacts();
});

/// FutureProvider.family: mengambil fun facts berdasarkan kategori.
/// Contoh: ref.watch(funFactsByCategoryProvider('literacy'))
final funFactsByCategoryProvider =
    FutureProvider.family<List<FunFactModel>, String>((ref, category) async {
  final service = ref.watch(funFactServiceProvider);
  return service.getFactsByCategory(category);
});

/// StateNotifier untuk tracking fun fact yang sudah ditampilkan dalam sesi game.
/// Mencegah fun fact yang sama muncul berulang kali.
class ShownFactsNotifier extends StateNotifier<List<String>> {
  ShownFactsNotifier() : super([]);

  /// Tandai fact sebagai sudah ditampilkan.
  void markAsShown(String factId) {
    state = [...state, factId];
  }

  /// Cek apakah fact sudah pernah ditampilkan.
  bool hasBeenShown(String factId) {
    return state.contains(factId);
  }

  /// Reset tracking (saat mulai game baru).
  void reset() {
    state = [];
  }
}

/// Provider untuk tracking fun facts yang sudah ditampilkan.
final shownFactsProvider =
    StateNotifierProvider<ShownFactsNotifier, List<String>>((ref) {
  return ShownFactsNotifier();
});
