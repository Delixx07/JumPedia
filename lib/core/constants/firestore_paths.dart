/// ═══════════════════════════════════════
/// FIRESTORE PATHS — SDG Eco-Jump
/// ═══════════════════════════════════════
/// Berisi semua string path koleksi dan dokumen Firestore.
/// Gunakan class ini agar path Firestore konsisten di seluruh app.
///
/// ═══════════════════════════════════════
/// SKEMA FIRESTORE:
/// ═══════════════════════════════════════
///
/// Collection 'users':
/// {
///   uid: String,              // UID dari Firebase Auth
///   username: String,         // Nama dari Google displayName
///   total_games_played: int,  // Counter total game dimainkan
///   created_at: Timestamp     // Waktu akun dibuat
/// }
///
/// Collection 'leaderboard':
/// {
///   user_id: DocumentReference, // Reference ke users/{uid}
///   score: int,                 // Skor yang dicapai
///   timestamp: Timestamp        // Waktu skor dicatat
/// }
///
/// Collection 'fun_facts':
/// {
///   fact_id: String,   // ID unik fakta
///   content: String,   // Isi fakta edukatif SDG 4
///   category: String   // Kategori fakta (e.g., 'literacy', 'access')
/// }
///
/// ═══════════════════════════════════════

class FirestorePaths {
  FirestorePaths._(); // Prevent instantiation

  // ─── Collection Names ─────────────────
  static const String usersCollection = 'users';
  static const String leaderboardCollection = 'leaderboard';
  static const String funFactsCollection = 'fun_facts';

  // ─── Document Paths ───────────────────

  /// Path ke dokumen user berdasarkan UID.
  /// Contoh: 'users/abc123'
  static String userDoc(String uid) => '$usersCollection/$uid';

  /// Path ke sub-field FCM token di dokumen user.
  /// Field ini disimpan langsung di dokumen user.
  static const String fcmTokenField = 'fcm_token';

  // ─── Field Names ──────────────────────
  static const String fieldUid = 'uid';
  static const String fieldUsername = 'username';
  static const String fieldTotalGamesPlayed = 'total_games_played';
  static const String fieldCreatedAt = 'created_at';
  static const String fieldUserId = 'user_id';
  static const String fieldScore = 'score';
  static const String fieldTimestamp = 'timestamp';
  static const String fieldFactId = 'fact_id';
  static const String fieldContent = 'content';
  static const String fieldCategory = 'category';
}
