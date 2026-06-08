import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/utils/logger.dart';
import '../models/collected_fact_model.dart';
import '../models/fun_fact_model.dart';

/// ═══════════════════════════════════════
/// COLLECTED FACT SERVICE — JumPedia
/// ═══════════════════════════════════════
/// Mengelola koleksi fun fact yang sudah didapatkan setiap user di dalam game.
/// Disimpan di subcollection 'users/{uid}/collected_facts'.
/// Service ini menyediakan operasi CRUD lengkap (Create, Read, Update, Delete).

class CollectedFactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection(FirestorePaths.collectedFactsPath(uid));

  /// ═══════════════════════════════════════
  /// CREATE — Tandai fact sebagai terkoleksi.
  /// ═══════════════════════════════════════
  /// Menggunakan `factId` sebagai document ID agar idempotent
  /// (memanggil method ini berkali-kali untuk fact yang sama tidak duplikat).
  /// Tidak menimpa `collected_at` jika sudah ada.
  ///
  /// Mengembalikan `true` jika fakta benar-benar disimpan, `false` jika
  /// dilewati karena duplikat (factId sama ATAU isi/content identik dengan
  /// fakta yang sudah ada — penting karena factId AI selalu unik per waktu).
  Future<bool> collectFact(String uid, FunFactModel fact) async {
    final docRef = _collection(uid).doc(fact.factId);
    final existing = await docRef.get();

    if (existing.exists) {
      AppLogger.firestore('SKIP', FirestorePaths.collectedFactsPath(uid),
          detail: 'Fact ${fact.factId} already collected');
      return false;
    }

    // Anti-duplikat berbasis isi: jika konten yang sama sudah pernah dikoleksi,
    // jangan simpan lagi (mencegah kartu kembar di koleksi).
    final contents = await getCollectedContents(uid);
    if (contents.contains(fact.content.trim().toLowerCase())) {
      AppLogger.firestore('SKIP', FirestorePaths.collectedFactsPath(uid),
          detail: 'Duplicate content skipped');
      return false;
    }

    // CRUD: CREATE
    await docRef.set({
      FirestorePaths.fieldFactId: fact.factId,
      FirestorePaths.fieldContent: fact.content,
      FirestorePaths.fieldCategory: fact.category,
      FirestorePaths.fieldCollectedAt: FieldValue.serverTimestamp(),
    });

    AppLogger.firestore('CREATE', FirestorePaths.collectedFactsPath(uid),
        detail: 'Fact ${fact.factId} collected');
    return true;
  }

  /// ═══════════════════════════════════════
  /// READ — Ambil semua fact yang sudah dikoleksi user (sekali ambil).
  /// ═══════════════════════════════════════
  Future<List<CollectedFactModel>> getCollectedFacts(String uid) async {
    // CRUD: READ
    final query = await _collection(uid)
        .orderBy(FirestorePaths.fieldCollectedAt, descending: true)
        .get();

    AppLogger.firestore('READ', FirestorePaths.collectedFactsPath(uid),
        detail: 'Fetched ${query.docs.length} collected facts');

    return query.docs.map((d) => CollectedFactModel.fromFirestore(d)).toList();
  }

  /// ═══════════════════════════════════════
  /// READ — Daftar isi (content) fakta yang sudah dikoleksi user.
  /// ═══════════════════════════════════════
  /// Dipakai untuk anti-duplikat: konten ini dikirim ke AI sebagai daftar
  /// "jangan ulang", dan dicek sebelum menyimpan fakta checkpoint baru.
  /// Dinormalisasi (lowercase + trim) agar perbandingan tahan beda spasi/kapital.
  Future<Set<String>> getCollectedContents(String uid) async {
    final query = await _collection(uid).get();
    return query.docs
        .map((d) => (d.data()[FirestorePaths.fieldContent] as String? ?? '')
            .trim()
            .toLowerCase())
        .where((c) => c.isNotEmpty)
        .toSet();
  }

  /// ═══════════════════════════════════════
  /// READ (stream) — Real-time list collected facts.
  /// ═══════════════════════════════════════
  Stream<List<CollectedFactModel>> streamCollectedFacts(String uid) {
    return _collection(uid)
        .orderBy(FirestorePaths.fieldCollectedAt, descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CollectedFactModel.fromFirestore(d))
            .toList());
  }

  /// ═══════════════════════════════════════
  /// UPDATE — Tandai / lepas favorit pada fakta yang dikoleksi.
  /// ═══════════════════════════════════════
  /// Hanya mengubah flag `is_favorite`; isi fakta tidak boleh diubah pemain.
  Future<void> setFavorite(
    String uid, {
    required String factId,
    required bool isFavorite,
  }) async {
    // CRUD: UPDATE
    await _collection(uid).doc(factId).update({
      FirestorePaths.fieldIsFavorite: isFavorite,
    });

    AppLogger.firestore('UPDATE', FirestorePaths.collectedFactsPath(uid),
        detail: 'Fact $factId is_favorite = $isFavorite');
  }

  /// ═══════════════════════════════════════
  /// DELETE — Hapus 1 fact dari koleksi user.
  /// ═══════════════════════════════════════
  Future<void> deleteCollectedFact(String uid, String factId) async {
    // CRUD: DELETE
    await _collection(uid).doc(factId).delete();

    AppLogger.firestore('DELETE', FirestorePaths.collectedFactsPath(uid),
        detail: 'Fact $factId removed from collection');
  }

  /// ═══════════════════════════════════════
  /// DELETE ALL — Reset seluruh koleksi user.
  /// ═══════════════════════════════════════
  /// Dipanggil dari tombol "Reset Koleksi" di Fun Facts page.
  /// Menggunakan batch agar atomic.
  Future<void> clearAllCollectedFacts(String uid) async {
    final snap = await _collection(uid).get();
    if (snap.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    // CRUD: DELETE (batch)
    await batch.commit();

    AppLogger.firestore('DELETE', FirestorePaths.collectedFactsPath(uid),
        detail: 'Cleared ${snap.docs.length} collected facts');
  }
}
