import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════
/// ACHIEVEMENT — JumPedia
/// ═══════════════════════════════════════
/// Lencana yang bisa dibuka pemain dari pencapaian di game. Status unlock
/// disimpan di Firestore (users/{uid}/achievements), sedangkan definisi
/// (ikon, syarat) statis di [AchievementCatalog].

/// Konteks data pemain untuk mengevaluasi syarat achievement.
class AchievementStats {
  final int bestScore;
  final int totalGames;
  final int factsCollected;

  const AchievementStats({
    required this.bestScore,
    required this.totalGames,
    required this.factsCollected,
  });
}

/// Definisi satu lencana (statis).
class AchievementDef {
  final String id;
  final IconData icon;
  final Color color;

  /// Judul & deskripsi diberikan dari luar (i18n) agar dwibahasa.
  final String Function(AchievementStrings) title;
  final String Function(AchievementStrings) description;

  /// Apakah syarat terpenuhi untuk stats tertentu.
  final bool Function(AchievementStats) isUnlocked;

  const AchievementDef({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });
}

/// Teks lencana (di-supply dari AppStrings agar dwibahasa).
abstract class AchievementStrings {
  String get achFirstGameTitle;
  String get achFirstGameDesc;
  String get achScore500Title;
  String get achScore500Desc;
  String get achScore1000Title;
  String get achScore1000Desc;
  String get achGames10Title;
  String get achGames10Desc;
  String get achGames50Title;
  String get achGames50Desc;
  String get achFacts10Title;
  String get achFacts10Desc;
  String get achFacts25Title;
  String get achFacts25Desc;
}

/// Katalog seluruh lencana yang ada di game.
class AchievementCatalog {
  AchievementCatalog._();

  static final List<AchievementDef> all = [
    AchievementDef(
      id: 'first_game',
      icon: Icons.sports_esports_rounded,
      color: const Color(0xFF22C55E),
      title: (s) => s.achFirstGameTitle,
      description: (s) => s.achFirstGameDesc,
      isUnlocked: (st) => st.totalGames >= 1,
    ),
    AchievementDef(
      id: 'score_500',
      icon: Icons.star_rounded,
      color: const Color(0xFFFFC107),
      title: (s) => s.achScore500Title,
      description: (s) => s.achScore500Desc,
      isUnlocked: (st) => st.bestScore >= 500,
    ),
    AchievementDef(
      id: 'score_1000',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFFFB300),
      title: (s) => s.achScore1000Title,
      description: (s) => s.achScore1000Desc,
      isUnlocked: (st) => st.bestScore >= 1000,
    ),
    AchievementDef(
      id: 'games_10',
      icon: Icons.repeat_rounded,
      color: const Color(0xFF1E88E5),
      title: (s) => s.achGames10Title,
      description: (s) => s.achGames10Desc,
      isUnlocked: (st) => st.totalGames >= 10,
    ),
    AchievementDef(
      id: 'games_50',
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFEF4444),
      title: (s) => s.achGames50Title,
      description: (s) => s.achGames50Desc,
      isUnlocked: (st) => st.totalGames >= 50,
    ),
    AchievementDef(
      id: 'facts_10',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFF6FB7FF),
      title: (s) => s.achFacts10Title,
      description: (s) => s.achFacts10Desc,
      isUnlocked: (st) => st.factsCollected >= 10,
    ),
    AchievementDef(
      id: 'facts_25',
      icon: Icons.auto_stories_rounded,
      color: const Color(0xFF0B5FBF),
      title: (s) => s.achFacts25Title,
      description: (s) => s.achFacts25Desc,
      isUnlocked: (st) => st.factsCollected >= 25,
    ),
  ];

  static AchievementDef? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}

/// Status unlock satu lencana (dari Firestore).
class AchievementUnlock {
  final String id;
  final Timestamp unlockedAt;

  const AchievementUnlock({required this.id, required this.unlockedAt});

  factory AchievementUnlock.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AchievementUnlock(
      id: data['id'] as String? ?? doc.id,
      unlockedAt: data['unlocked_at'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
