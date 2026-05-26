import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/collected_fact_model.dart';
import '../services/collected_fact_service.dart';
import 'auth_provider.dart';

/// ═══════════════════════════════════════
/// COLLECTED FACT PROVIDERS — JumPedia
/// ═══════════════════════════════════════
/// Provider Riverpod untuk subcollection users/{uid}/collected_facts.

/// Provider singleton untuk service.
final collectedFactServiceProvider = Provider<CollectedFactService>((ref) {
  return CollectedFactService();
});

/// StreamProvider untuk daftar fact yang dikoleksi user yang sedang login.
/// Otomatis null/empty jika belum login.
final collectedFactsStreamProvider =
    StreamProvider.autoDispose<List<CollectedFactModel>>((ref) {
  final uid = ref.watch(currentUserUidProvider);
  if (uid == null) {
    return const Stream.empty();
  }
  final service = ref.watch(collectedFactServiceProvider);
  return service.streamCollectedFacts(uid);
});
