import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/utils/logger.dart';
import '../models/leaderboard_model.dart';

/// ═══════════════════════════════════════
/// SCORE SERVICE — SDG Eco-Jump
/// ═══════════════════════════════════════
/// Mengelola operasi CRUD ke koleksi 'leaderboard' dan update statistik user.
/// Setiap method ditandai dengan komentar CRUD operation-nya.

class ScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ═══════════════════════════════════════
  /// SAVE SCORE
  /// ═══════════════════════════════════════
  /// // CRUD: CREATE — Buat dokumen baru di koleksi 'leaderboard'.
  /// Menyimpan skor dari sesi permainan yang baru selesai.
  Future<void> saveScore(String userId, int score) async {
    // Buat reference ke dokumen user untuk disimpan sebagai DocumentReference
    final userRef =
        _firestore.collection(FirestorePaths.usersCollection).doc(userId);

    final scoreData = {
      FirestorePaths.fieldUserId: userRef, // DocumentReference ke users/{uid}
      FirestorePaths.fieldScore: score,
      FirestorePaths.fieldTimestamp: FieldValue.serverTimestamp(),
    };

    // CRUD: CREATE
    await _firestore
        .collection(FirestorePaths.leaderboardCollection)
        .add(scoreData);

    AppLogger.firestore('CREATE', FirestorePaths.leaderboardCollection,
        detail: 'Score $score saved for user $userId');
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
    final userRef =
        _firestore.collection(FirestorePaths.usersCollection).doc(userId);

    // CRUD: READ
    final querySnapshot = await _firestore
        .collection(FirestorePaths.leaderboardCollection)
        .where(FirestorePaths.fieldUserId, isEqualTo: userRef)
        .orderBy(FirestorePaths.fieldScore, descending: true)
        .limit(1)
        .get();

    AppLogger.firestore('READ', FirestorePaths.leaderboardCollection,
        detail: 'Best score for user $userId');

    if (querySnapshot.docs.isEmpty) return 0;
    return querySnapshot.docs.first.data()[FirestorePaths.fieldScore] as int;
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
