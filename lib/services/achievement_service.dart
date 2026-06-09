import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/utils/logger.dart';
import '../models/achievement_model.dart';

/// ═══════════════════════════════════════
/// ACHIEVEMENT SERVICE — JumPedia
/// ═══════════════════════════════════════
/// Mengelola status unlock lencana di Firestore (users/{uid}/achievements).
/// Definisi lencana statis di [AchievementCatalog]; di sini hanya menyimpan
/// MANA yang sudah terbuka + kapan.
class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection(FirestorePaths.achievementsPath(uid));

  /// READ (stream) — id lencana yang sudah terbuka (real-time).
  Stream<Set<String>> streamUnlockedIds(String uid) {
    return _collection(uid).snapshots().map(
          (snap) => snap.docs.map((d) => d.id).toSet(),
        );
  }

  /// READ — id lencana yang sudah terbuka (sekali ambil).
  Future<Set<String>> getUnlockedIds(String uid) async {
    final snap = await _collection(uid).get();
    return snap.docs.map((d) => d.id).toSet();
  }

  /// EVALUATE + CREATE — periksa seluruh katalog terhadap [stats]; lencana
  /// yang syaratnya terpenuhi & belum tercatat akan disimpan (unlock).
  /// Mengembalikan daftar lencana yang BARU terbuka pada panggilan ini.
  Future<List<AchievementDef>> evaluateAndUnlock(
    String uid,
    AchievementStats stats,
  ) async {
    final alreadyUnlocked = await getUnlockedIds(uid);
    final newlyUnlocked = <AchievementDef>[];

    final batch = _firestore.batch();
    for (final def in AchievementCatalog.all) {
      if (alreadyUnlocked.contains(def.id)) continue;
      if (!def.isUnlocked(stats)) continue;

      // CRUD: CREATE — tandai lencana terbuka (doc id = achievement id).
      batch.set(_collection(uid).doc(def.id), {
        'id': def.id,
        'unlocked_at': FieldValue.serverTimestamp(),
      });
      newlyUnlocked.add(def);
    }

    if (newlyUnlocked.isNotEmpty) {
      await batch.commit();
      AppLogger.firestore('CREATE', FirestorePaths.achievementsPath(uid),
          detail: 'Unlocked: ${newlyUnlocked.map((e) => e.id).join(', ')}');
    }
    return newlyUnlocked;
  }
}
