import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fun_fact_model.dart';
import '../services/fun_fact_service.dart';
import '../services/gemini_fun_fact_service.dart';
import 'auth_provider.dart';
import 'collected_fact_provider.dart';
import 'language_provider.dart';

/// ═══════════════════════════════════════
/// FUN FACT PROVIDER — JumPedia
/// ═══════════════════════════════════════
/// Provider untuk data fun facts.
/// Digunakan oleh fun_fact_overlay.dart saat player mencapai checkpoint.
///
/// Sumber fun fact sekarang adalah AI (Google Gemini) yang men-generate
/// fakta SDG 4 secara real-time. Provider berbasis Firestore di bawah
/// (allFunFactsProvider, dll.) masih dipertahankan untuk kompatibilitas,
/// tetapi tidak lagi dipakai oleh overlay.

/// Provider untuk instance FunFactService (Firestore — legacy).
final funFactServiceProvider = Provider<FunFactService>((ref) {
  return FunFactService();
});

/// ═══════════════════════════════════════
/// GEMINI (AI) PROVIDERS
/// ═══════════════════════════════════════

/// Provider singleton untuk service AI Gemini.
final geminiFunFactServiceProvider = Provider<GeminiFunFactService>((ref) {
  return GeminiFunFactService();
});

/// Menghitung berapa kali checkpoint sudah dilewati dalam satu sesi.
/// Dinaikkan tiap kali GameWorld memicu fun fact, sehingga overlay
/// men-generate fakta AI yang baru pada tiap checkpoint.
class FactCheckpointNotifier extends StateNotifier<int> {
  FactCheckpointNotifier() : super(0);

  /// Lanjut ke checkpoint berikutnya (memicu fetch fakta AI baru).
  void next() => state = state + 1;

  /// Reset saat mulai game baru.
  void reset() => state = 0;
}

/// Counter checkpoint aktif. Dipakai sebagai "kunci" untuk memaksa
/// [aiFunFactProvider] menghasilkan fakta baru tiap checkpoint.
final factCheckpointProvider =
    StateNotifierProvider<FactCheckpointNotifier, int>((ref) {
  return FactCheckpointNotifier();
});

/// FutureProvider.family: men-generate satu fun fact AI untuk nomor
/// checkpoint tertentu. Hasil di-cache per-checkpoint oleh Riverpod, jadi
/// rebuild overlay (mis. animasi) tidak memanggil AI berulang kali.
final aiFunFactProvider =
    FutureProvider.family<FunFactModel, int>((ref, checkpoint) async {
  final service = ref.watch(geminiFunFactServiceProvider);
  // Baca (bukan watch) bahasa: fakta untuk checkpoint ini dibuat sekali
  // dengan bahasa yang aktif saat checkpoint terpicu.
  final language = ref.read(factLanguageProvider);

  // Anti-duplikat lintas-sesi: ambil isi fakta yang sudah dikoleksi user agar
  // AI tidak mengulang fakta yang sudah ada di koleksinya.
  var avoid = const <String>{};
  final uid = ref.read(currentUserUidProvider);
  if (uid != null) {
    try {
      avoid = await ref.read(collectedFactServiceProvider).getCollectedContents(uid);
    } catch (_) {
      // gagal baca koleksi — lanjut tanpa daftar hindari.
    }
  }

  return service.generateFact(language: language, avoidContents: avoid);
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
