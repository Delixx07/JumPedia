import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/achievement_service.dart';
import 'auth_provider.dart';

/// ═══════════════════════════════════════
/// ACHIEVEMENT PROVIDERS — JumPedia
/// ═══════════════════════════════════════
/// Provider Riverpod untuk subcollection users/{uid}/achievements.

/// Provider singleton untuk service.
final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService();
});

/// Stream id lencana yang sudah terbuka untuk user yang sedang login.
final unlockedAchievementsProvider =
    StreamProvider.autoDispose<Set<String>>((ref) {
  final uid = ref.watch(currentUserUidProvider);
  if (uid == null) return Stream.value(const <String>{});
  return ref.watch(achievementServiceProvider).streamUnlockedIds(uid);
});
