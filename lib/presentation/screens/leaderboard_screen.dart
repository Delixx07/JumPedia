import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/leaderboard_model.dart';
import '../../services/score_service.dart';

/// Leaderboard Screen — Top scores dari semua pemain.
final topScoresProvider = FutureProvider<List<LeaderboardModel>>((ref) async {
  final scoreService = ScoreService();
  return scoreService.getTopScores(limit: 10);
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoresAsync = ref.watch(topScoresProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF16213E)],
          ),
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
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text('Leaderboard', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      onPressed: () => ref.invalidate(topScoresProvider),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 48),
              const SizedBox(height: 16),
              Expanded(
                child: scoresAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
                  error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                  data: (scores) {
                    if (scores.isEmpty) {
                      return const Center(child: Text('Belum ada skor', style: TextStyle(color: Colors.white54)));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: scores.length,
                      itemBuilder: (context, i) {
                        final entry = scores[i];
                        final rank = i + 1;
                        final color = rank == 1 ? const Color(0xFFFFD700) : rank == 2 ? const Color(0xFFC0C0C0) : rank == 3 ? const Color(0xFFCD7F32) : Colors.white54;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Row(children: [
                            Text('#$rank', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 16),
                            Expanded(child: Text(entry.username ?? 'Player', style: const TextStyle(color: Colors.white, fontSize: 16))),
                            Text('${entry.score}', style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.w800)),
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
