import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk koleksi 'users' di Firestore.
/// Menyimpan data profil pemain termasuk statistik permainan.
class UserModel {
  final String uid;
  final String username;
  final int totalGamesPlayed;
  final Timestamp createdAt;

  const UserModel({
    required this.uid,
    required this.username,
    required this.totalGamesPlayed,
    required this.createdAt,
  });

  /// Factory constructor dari Firestore DocumentSnapshot.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] as String? ?? doc.id,
      username: data['username'] as String? ?? 'Unknown',
      totalGamesPlayed: data['total_games_played'] as int? ?? 0,
      createdAt: data['created_at'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'username': username,
      'total_games_played': totalGamesPlayed,
      'created_at': createdAt,
    };
  }

  /// Copy-with untuk immutability.
  UserModel copyWith({
    String? uid,
    String? username,
    int? totalGamesPlayed,
    Timestamp? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
