// ═══════════════════════════════════════
// FIRESTORE PATHS — JumPedia
// ═══════════════════════════════════════
// Berisi semua string path koleksi dan dokumen Firestore.
// Gunakan class ini agar path Firestore konsisten di seluruh app.
//
// ═══════════════════════════════════════
// SKEMA FIRESTORE:
// ═══════════════════════════════════════
//
// Collection 'users':
// {
//   uid: String,              // UID dari Firebase Auth
//   username: String,         // Nama dari Google displayName
//   total_games_played: int,  // Counter total game dimainkan
//   created_at: Timestamp     // Waktu akun dibuat
// }
//
// Collection 'leaderboard':
// {
//   user_id: DocumentReference, // Reference ke users/{uid}
//   score: int,                 // Skor yang dicapai
//   timestamp: Timestamp        // Waktu skor dicatat
// }
//
// Collection 'fun_facts':
// {
//   fact_id: String,   // ID unik fakta
//   content: String,   // Isi fakta edukatif SDG 4
//   category: String   // Kategori fakta (e.g., 'literacy', 'access')
// }
//
// Subcollection 'users/{uid}/collected_facts':
// {
//   fact_id: String,         // ID fakta yang dikoleksi (= doc ID)
//   content: String,         // Snapshot isi fakta saat dikoleksi
//   category: String,        // Snapshot kategori
//   collected_at: Timestamp, // Waktu fakta dikoleksi
//   is_favorite: bool        // Ditandai favorit oleh pemain (toggle)
// }
//
// ═══════════════════════════════════════

class FirestorePaths {
  FirestorePaths._(); // Prevent instantiation

  // ─── Collection Names ─────────────────
  static const String usersCollection = 'users';
  static const String leaderboardCollection = 'leaderboard';
  static const String funFactsCollection = 'fun_facts';
  static const String collectedFactsSubcollection = 'collected_facts';
  static const String achievementsSubcollection = 'achievements';
  static const String scoreHistorySubcollection = 'score_history';

  // ─── Document Paths ───────────────────

  /// Path ke dokumen user berdasarkan UID.
  /// Contoh: 'users/abc123'
  static String userDoc(String uid) => '$usersCollection/$uid';

  /// Path ke subcollection collected_facts milik user.
  /// Contoh: 'users/abc123/collected_facts'
  static String collectedFactsPath(String uid) =>
      '$usersCollection/$uid/$collectedFactsSubcollection';

  /// Path ke subcollection achievements milik user.
  static String achievementsPath(String uid) =>
      '$usersCollection/$uid/$achievementsSubcollection';

    /// Path ke subcollection score_history milik user.
    /// Contoh: 'users/abc123/score_history'
    static String scoreHistoryPath(String uid) =>
      '$usersCollection/$uid/$scoreHistorySubcollection';

  /// Path ke sub-field FCM token di dokumen user.
  /// Field ini disimpan langsung di dokumen user.
  static const String fcmTokenField = 'fcm_token';

  // ─── Field Names ──────────────────────
  static const String fieldUid = 'uid';
  static const String fieldUsername = 'username';
  static const String fieldAvatarPath = 'avatar_path';
  static const String fieldPhotoUrl = 'photo_url';
  static const String fieldNotificationsEnabled = 'notifications_enabled';
  static const String fieldTotalGamesPlayed = 'total_games_played';
  static const String fieldCreatedAt = 'created_at';
  static const String fieldUserId = 'user_id';
  static const String fieldScore = 'score';
  static const String fieldTimestamp = 'timestamp';
  static const String fieldFactId = 'fact_id';
  static const String fieldContent = 'content';
  static const String fieldCategory = 'category';
  static const String fieldCollectedAt = 'collected_at';
  static const String fieldIsFavorite = 'is_favorite';
}
