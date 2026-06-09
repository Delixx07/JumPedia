import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/leaderboard_model.dart';
import '../../providers/ui_language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/score_service.dart';
import '../widgets/state_views.dart';

/// Leaderboard Screen — Top scores dari semua pemain.
final topScoresProvider = FutureProvider<List<LeaderboardModel>>((ref) async {
  final scoreService = ScoreService();
  final uid = ref.watch(currentUserUidProvider);
  if (uid != null) {
    // Sinkronisasi manual untuk user saat ini sebelum menampilkan papan skor.
    await scoreService.syncUserLeaderboardFromHistory(uid);
  }
  return scoreService.getTopScores(limit: 10);
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoresAsync = ref.watch(topScoresProvider);
    final s = ref.watch(uiStringsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.textHi),
                    ),
                    Expanded(
                      child: Text(s.leaderboard, textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textHi, fontSize: 24, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      onPressed: () => ref.invalidate(topScoresProvider),
                      icon: const Icon(Icons.refresh, color: AppColors.textHi),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.emoji_events_rounded, color: AppColors.warn, size: 48),
              const SizedBox(height: 16),
              Expanded(
                child: scoresAsync.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(
                    message: '${s.error}: $e',
                    onRetry: () => ref.invalidate(topScoresProvider),
                  ),
                  data: (scores) {
                    if (scores.isEmpty) {
                      return EmptyView(
                        icon: Icons.emoji_events_outlined,
                        title: s.noScoresYet,
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: scores.length,
                      itemBuilder: (context, i) {
                        final entry = scores[i];
                        final rank = i + 1;
                        final rankColor = rank == 1
                            ? const Color(0xFFFFB300)
                            : rank == 2
                                ? const Color(0xFF9E9E9E)
                                : rank == 3
                                    ? const Color(0xFFB87333)
                                    : AppColors.textLo;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgMid,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: rankColor.withValues(alpha: 0.5)),
                          ),
                          child: Row(children: [
                            Text('#$rank', style: TextStyle(color: rankColor, fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 16),
                            Expanded(child: Text(entry.username ?? s.player, style: const TextStyle(color: AppColors.textHi, fontSize: 16))),
                            Text('${entry.score}', style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w800)),
                          ]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
