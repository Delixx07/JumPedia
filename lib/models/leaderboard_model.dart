import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk koleksi 'leaderboard' di Firestore.
/// Menyimpan skor individual setiap sesi permainan.
class LeaderboardModel {
  final String? id; // Document ID (auto-generated)
  final DocumentReference userId; // Reference ke users/{uid}
  final int score;
  final Timestamp timestamp;

  // Field tambahan untuk display (di-resolve dari userId reference)
  final String? username;

  const LeaderboardModel({
    this.id,
    required this.userId,
    required this.score,
    required this.timestamp,
    this.username,
  });

  /// Factory constructor dari Firestore DocumentSnapshot.
  factory LeaderboardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardModel(
      id: doc.id,
      userId: data['user_id'] as DocumentReference,
      score: data['score'] as int? ?? 0,
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'score': score,
      'timestamp': timestamp,
    };
  }

  /// Copy-with untuk menambahkan username setelah resolve reference.
  LeaderboardModel copyWith({String? username}) {
    return LeaderboardModel(
      id: id,
      userId: userId,
      score: score,
      timestamp: timestamp,
      username: username ?? this.username,
    );
  }
}
