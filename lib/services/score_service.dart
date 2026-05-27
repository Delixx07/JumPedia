import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/utils/logger.dart';
import '../models/leaderboard_model.dart';

/// ═══════════════════════════════════════
/// SCORE SERVICE — JumPedia
/// ═══════════════════════════════════════
/// Mengelola operasi CRUD ke koleksi 'leaderboard' dan update statistik user.
/// Setiap method ditandai dengan komentar CRUD operation-nya.

class ScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ═══════════════════════════════════════
  /// SAVE SCORE
  /// ═══════════════════════════════════════
  /// // CRUD: UPDATE — Update atau buat dokumen di koleksi 'leaderboard'.
  /// Menyimpan skor tertinggi dari sesi permainan yang baru selesai.
  Future<void> saveScore(String userId, int score) async {
    // Cek dulu apakah skor baru lebih baik dari skor lama
    final currentBest = await getUserBestScore(userId);

    if (score > currentBest) {
      // Buat reference ke dokumen user untuk disimpan sebagai DocumentReference
      final userRef =
          _firestore.collection(FirestorePaths.usersCollection).doc(userId);

      final scoreData = {
        FirestorePaths.fieldUserId: userRef, // DocumentReference ke users/{uid}
        FirestorePaths.fieldScore: score,
        FirestorePaths.fieldTimestamp: FieldValue.serverTimestamp(),
      };

      // CRUD: UPDATE (menggunakan userId sebagai document ID agar overwrite)
      await _firestore
          .collection(FirestorePaths.leaderboardCollection)
          .doc(userId)
          .set(scoreData);

      AppLogger.firestore('UPDATE', FirestorePaths.leaderboardCollection,
          detail: 'New high score $score saved for user $userId');
    } else {
      AppLogger.game('Score $score is not better than $currentBest. No update.');
    }
  }

  /// ═══════════════════════════════════════
  /// GET TOP SCORES
  /// ═══════════════════════════════════════
  /// // CRUD: READ — Baca koleksi leaderboard, order by score desc.
  /// Mengembalikan top [limit] skor tertinggi dari semua pemain.
  Future<List<LeaderboardModel>> getTopScores({int limit = 10}) async {
    // CRUD: READ
    final querySnapshot = await _firestore
        .collection(FirestorePaths.leaderboardCollection)
        .orderBy(FirestorePaths.fieldScore, descending: true)
        .limit(limit)
        .get();

    AppLogger.firestore('READ', FirestorePaths.leaderboardCollection,
        detail: 'Fetched top $limit scores');

    return querySnapshot.docs
        .map((doc) => LeaderboardModel.fromFirestore(doc))
        .toList();
  }

  /// ═══════════════════════════════════════
  /// GET USER BEST SCORE
  /// ═══════════════════════════════════════
  /// // CRUD: READ — Baca skor tertinggi milik user tertentu.
  Future<int> getUserBestScore(String userId) async {
    // CRUD: READ - Langsung ambil dokumen berdasarkan userId
    final doc = await _firestore
        .collection(FirestorePaths.leaderboardCollection)
        .doc(userId)
        .get();

    AppLogger.firestore('READ', FirestorePaths.leaderboardCollection,
        detail: 'Fetching best score for user $userId');

    if (!doc.exists) return 0;
    final data = doc.data();
    return data?[FirestorePaths.fieldScore] as int? ?? 0;
  }

  /// ═══════════════════════════════════════
  /// INCREMENT GAMES PLAYED
  /// ═══════════════════════════════════════
  /// // CRUD: UPDATE — Update field total_games_played di users/{uid}.
  /// Menggunakan FieldValue.increment(1) untuk atomic increment.
  Future<void> incrementGamesPlayed(String userId) async {
    // CRUD: UPDATE
    await _firestore
        .collection(FirestorePaths.usersCollection)
        .doc(userId)
        .update({
      FirestorePaths.fieldTotalGamesPlayed: FieldValue.increment(1),
    });

    AppLogger.firestore('UPDATE', FirestorePaths.userDoc(userId),
        detail: 'Incremented total_games_played');
  }
}
