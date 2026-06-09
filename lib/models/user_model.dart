import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';

/// Model untuk koleksi 'users' di Firestore.
/// Menyimpan data profil pemain termasuk statistik permainan.
class UserModel {
  final String uid;
  final String username;
  final String avatarPath;
  final String? photoUrl;
  final bool notificationsEnabled;
  final int totalGamesPlayed;
  final Timestamp createdAt;

  const UserModel({
    required this.uid,
    required this.username,
    required this.avatarPath,
    this.photoUrl,
    required this.notificationsEnabled,
    required this.totalGamesPlayed,
    required this.createdAt,
  });

  /// Factory constructor dari Firestore DocumentSnapshot.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data[FirestorePaths.fieldUid] as String? ?? doc.id,
      username: data[FirestorePaths.fieldUsername] as String? ?? 'Unknown',
      avatarPath: data[FirestorePaths.fieldAvatarPath] as String? ?? 'panda.png',
      photoUrl: data[FirestorePaths.fieldPhotoUrl] as String?,
      notificationsEnabled: data[FirestorePaths.fieldNotificationsEnabled] as bool? ?? true,
      totalGamesPlayed: data[FirestorePaths.fieldTotalGamesPlayed] as int? ?? 0,
      createdAt: data[FirestorePaths.fieldCreatedAt] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      FirestorePaths.fieldUid: uid,
      FirestorePaths.fieldUsername: username,
      FirestorePaths.fieldAvatarPath: avatarPath,
      FirestorePaths.fieldPhotoUrl: photoUrl,
      FirestorePaths.fieldNotificationsEnabled: notificationsEnabled,
      FirestorePaths.fieldTotalGamesPlayed: totalGamesPlayed,
      FirestorePaths.fieldCreatedAt: createdAt,
    };
  }

  /// Copy-with untuk immutability.
  UserModel copyWith({
    String? uid,
    String? username,
    String? avatarPath,
    String? photoUrl,
    bool? notificationsEnabled,
    int? totalGamesPlayed,
    Timestamp? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      avatarPath: avatarPath ?? this.avatarPath,
      photoUrl: photoUrl ?? this.photoUrl,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
