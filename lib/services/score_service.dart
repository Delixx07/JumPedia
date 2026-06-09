import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/utils/logger.dart';
import '../models/leaderboard_model.dart';
import '../models/score_history_model.dart';

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

    // Selain update leaderboard, selalu simpan entri riwayat skor di
    // subcollection users/{uid}/score_history sehingga kita punya log lengkap
    // dari setiap sesi (timestamp + score).
    try {
      await _firestore
          .collection(FirestorePaths.scoreHistoryPath(userId))
          .add({
        FirestorePaths.fieldScore: score,
        FirestorePaths.fieldTimestamp: FieldValue.serverTimestamp(),
      });

      AppLogger.firestore('CREATE', FirestorePaths.scoreHistoryPath(userId),
          detail: 'Recorded score $score for user $userId');
    } catch (e) {
      AppLogger.firestore('ERROR', FirestorePaths.scoreHistoryPath(userId),
          detail: 'Failed to record score history: $e');
    }
  }

    /// GET USER SCORE HISTORY
    /// // CRUD: READ — Baca riwayat skor milik user tertentu.
    /// Menggunakan query default tanpa ordering agar tidak memerlukan index.
    Future<List<ScoreHistoryModel>> getUserScoreHistory(String userId,
      {int limit = 50}) async {
      final querySnapshot = await _firestore
        .collection(FirestorePaths.scoreHistoryPath(userId))
        .limit(limit)
        .get();

    AppLogger.firestore('READ', FirestorePaths.scoreHistoryPath(userId),
      detail: 'Fetched $limit score history items for $userId (no ordering)');

    return querySnapshot.docs
      .map((d) => ScoreHistoryModel.fromFirestore(d))
      .toList();
    }

  /// DELETE A SINGLE SCORE HISTORY ITEM
  Future<void> deleteScoreHistoryItem(String userId, String historyId) async {
    try {
      await _firestore
          .collection(FirestorePaths.scoreHistoryPath(userId))
          .doc(historyId)
          .delete();
      AppLogger.firestore('DELETE',
          '${FirestorePaths.scoreHistoryPath(userId)}/$historyId',
          detail: 'Deleted score history $historyId for user $userId');
    } catch (e) {
      AppLogger.firestore('ERROR', FirestorePaths.scoreHistoryPath(userId),
          detail: 'Failed to delete score history $historyId: $e');
      rethrow;
    }
  }

  /// DELETE ALL SCORE HISTORY for a user (batch delete)
  Future<void> deleteAllScoreHistory(String userId) async {
    final col = _firestore.collection(FirestorePaths.scoreHistoryPath(userId));
    try {
      final snapshot = await col.get();
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final d in snapshot.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      AppLogger.firestore('DELETE', FirestorePaths.scoreHistoryPath(userId),
          detail: 'Deleted all score history for user $userId');
    } catch (e) {
      AppLogger.firestore('ERROR', FirestorePaths.scoreHistoryPath(userId),
          detail: 'Failed to delete all score history: $e');
      rethrow;
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

    // Map documents to models, then resolve each user reference to get username.
    final models = querySnapshot.docs
        .map((doc) => LeaderboardModel.fromFirestore(doc))
        .toList();

    // Resolve usernames in parallel for performance.
    final resolved = await Future.wait(models.map((m) async {
      try {
        final userSnap = await m.userId.get();
        if (userSnap.exists) {
          final data = userSnap.data() as Map<String, dynamic>?;
          final username = data?[FirestorePaths.fieldUsername] as String?;
          return m.copyWith(username: username ?? 'Player');
        }
      } catch (e) {
        AppLogger.firestore('ERROR', FirestorePaths.usersCollection,
            detail: 'Failed to resolve username for leaderboard entry: $e');
      }
      return m.copyWith(username: 'Player');
    }));

    return resolved;
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

  /// SYNC LEADERBOARD FROM HISTORY
  /// Mengambil skor tertinggi dari `users/{userId}/score_history` dan
  /// menyamakan dokumen `leaderboard/{userId}` dengan nilai tersebut.
  /// Jika tidak ada riwayat, dokumen leaderboard akan dihapus.
  Future<void> syncUserLeaderboardFromHistory(String userId) async {
    try {
      final historyCol = _firestore.collection(FirestorePaths.scoreHistoryPath(userId));

      // Ambil skor tertinggi dari riwayat (orderBy score desc, limit 1)
      final topSnap = await historyCol.orderBy(FirestorePaths.fieldScore, descending: true).limit(1).get();

      if (topSnap.docs.isEmpty) {
        // Tidak ada riwayat: hapus entry leaderboard jika ada
        await _firestore.collection(FirestorePaths.leaderboardCollection).doc(userId).delete().catchError((_) {});
        AppLogger.firestore('SYNC', FirestorePaths.leaderboardCollection,
            detail: 'No history found — deleted leaderboard entry for $userId');
        return;
      }

      final topDoc = topSnap.docs.first;
      final topData = topDoc.data();
      final topScoreNum = topData[FirestorePaths.fieldScore] as num?;
      final topScore = topScoreNum?.toInt() ?? 0;

      // Ambil dokumen leaderboard sekarang
      final lbRef = _firestore.collection(FirestorePaths.leaderboardCollection).doc(userId);
      final lbDoc = await lbRef.get();
      final lbScore = lbDoc.exists ? (lbDoc.data()?[FirestorePaths.fieldScore] as num?)?.toInt() ?? 0 : null;

      // Jika berbeda, update (atau buat) dokumen leaderboard
      if (lbScore == null || lbScore != topScore) {
        final userRef = _firestore.collection(FirestorePaths.usersCollection).doc(userId);
        await lbRef.set({
          FirestorePaths.fieldUserId: userRef,
          FirestorePaths.fieldScore: topScore,
          FirestorePaths.fieldTimestamp: FieldValue.serverTimestamp(),
        });
        AppLogger.firestore('SYNC', FirestorePaths.leaderboardCollection,
            detail: 'Synchronized leaderboard for $userId -> $topScore');
      } else {
        AppLogger.firestore('SYNC', FirestorePaths.leaderboardCollection,
            detail: 'Leaderboard for $userId already up-to-date ($lbScore)');
      }
    } catch (e) {
      AppLogger.firestore('ERROR', FirestorePaths.leaderboardCollection,
          detail: 'Failed to sync leaderboard from history for $userId: $e');
    }
  }

  /// ═══════════════════════════════════════
  /// DELETE SCORE
  /// ═══════════════════════════════════════
  /// // CRUD: DELETE — Hapus dokumen skor milik user dari leaderboard.
  Future<void> deleteScore(String userId) async {
    // CRUD: DELETE
    await _firestore
        .collection(FirestorePaths.leaderboardCollection)
        .doc(userId)
        .delete();

    AppLogger.firestore('DELETE', FirestorePaths.leaderboardCollection,
        detail: 'Score deleted for user $userId');
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
