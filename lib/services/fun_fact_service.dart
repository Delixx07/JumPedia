import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/utils/logger.dart';
import '../models/fun_fact_model.dart';

/// ═══════════════════════════════════════
/// FUN FACT SERVICE — JumPedia
/// ═══════════════════════════════════════
/// Membaca koleksi 'fun_facts' dari Firestore.
/// Koleksi ini diisi melalui Firebase Console / admin dashboard, bukan dari app.
/// Berisi fakta-fakta edukatif bertema SDG 4 (Pendidikan Berkualitas).

class FunFactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ═══════════════════════════════════════
  /// GET ALL FACTS
  /// ═══════════════════════════════════════
  /// // CRUD: READ — Baca semua dokumen dari koleksi 'fun_facts'.
  Future<List<FunFactModel>> getAllFacts() async {
    // CRUD: READ
    final querySnapshot =
        await _firestore.collection(FirestorePaths.funFactsCollection).get();

    AppLogger.firestore('READ', FirestorePaths.funFactsCollection,
        detail: 'Fetched ${querySnapshot.docs.length} fun facts');

    return querySnapshot.docs
        .map((doc) => FunFactModel.fromFirestore(doc))
        .toList();
  }

  /// ═══════════════════════════════════════
  /// GET FACTS BY CATEGORY
  /// ═══════════════════════════════════════
  /// // CRUD: READ — Baca fun facts dengan filter berdasarkan kategori.
  /// Kategori contoh: 'literacy', 'access', 'equality', 'quality'
  Future<List<FunFactModel>> getFactsByCategory(String category) async {
    // CRUD: READ
    final querySnapshot = await _firestore
        .collection(FirestorePaths.funFactsCollection)
        .where(FirestorePaths.fieldCategory, isEqualTo: category)
        .get();

    AppLogger.firestore('READ', FirestorePaths.funFactsCollection,
        detail: 'Fetched facts for category: $category');

    return querySnapshot.docs
        .map((doc) => FunFactModel.fromFirestore(doc))
        .toList();
  }

  /// ═══════════════════════════════════════
  /// GET RANDOM FACT
  /// ═══════════════════════════════════════
  /// // CRUD: READ — Ambil satu fakta random dari semua fun facts.
  /// Digunakan oleh game_world.dart saat player mencapai ketinggian tertentu.
  Future<FunFactModel?> getRandomFact() async {
    final allFacts = await getAllFacts();
    if (allFacts.isEmpty) return null;

    // Shuffle dan ambil yang pertama
    allFacts.shuffle();
    return allFacts.first;
  }
}
