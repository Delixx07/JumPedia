import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/fun_fact_provider.dart';
import '../../providers/score_provider.dart';
import '../widgets/sdg_button.dart';

/// ═══════════════════════════════════════
/// GAME OVER SCREEN — JumPedia
/// ═══════════════════════════════════════
/// Ditampilkan setelah player meninggal (HP = 0 atau jatuh).
/// Memberikan: skor akhir, fun fact bonus (reward checkpoint terakhir),
/// dan opsi untuk Restart (main lagi) atau Back Home.

/// Fallback fun facts ketika koleksi Firestore kosong / gagal load.
const _fallbackFacts = [
  '258 million children and young people around the world are still out of '
      'school. Quality education is the key to a better future!',
  'Each additional year of education raises a person\'s average income by '
      'about 10%.',
  'Reading 20 minutes a day exposes a child to roughly 1.8 million words '
      'per year.',
  'SDG 4 targets inclusive, equitable, and quality education for all by 2030.',
];

class GameOverScreen extends ConsumerWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finalScore = ref.read(scoreProvider);
    final factsAsync = ref.watch(allFunFactsProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgTop, AppColors.bgMid],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // ─── Title ───────────────────────────
                const Icon(
                  Icons.sentiment_very_dissatisfied_rounded,
                  color: AppColors.danger,
                  size: 64,
                ),
                const SizedBox(height: 8),
                const Text(
                  'GAME OVER',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your character is gone... but the knowledge stays 📚',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textLo,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 28),

                // ─── Final Score Card ────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.bgMid, AppColors.bgTop],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.warn.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warn.withValues(alpha: 0.2),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.warn,
                        size: 44,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'FINAL SCORE',
                        style: TextStyle(
                          color: AppColors.warn,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        finalScore.toString(),
                        style: const TextStyle(
                          color: AppColors.textHi,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─── Checkpoint Reward: Fun Fact ─────
                _FunFactReward(factsAsync: factsAsync),

                const SizedBox(height: 24),

                // ─── Action Buttons ──────────────────
                SdgButton(
                  text: 'Restart — Play Again',
                  icon: Icons.refresh_rounded,
                  onPressed: () => context.go('/game'),
                ),
                const SizedBox(height: 12),
                SdgButton(
                  text: 'Back to Home',
                  icon: Icons.home_rounded,
                  style: SdgButtonStyle.secondary,
                  onPressed: () => context.go('/home'),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => context.go('/leaderboard'),
                  icon: const Icon(
                    Icons.leaderboard_rounded,
                    color: AppColors.textLo,
                    size: 18,
                  ),
                  label: const Text(
                    'View Leaderboard',
                    style: TextStyle(color: AppColors.textLo),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu reward berisi fun fact acak — diberikan setelah game over
/// sebagai "checkpoint terakhir" agar pemain tetap mendapat edukasi.
class _FunFactReward extends StatelessWidget {
  final AsyncValue factsAsync;
  const _FunFactReward({required this.factsAsync});

  String _pickFact(dynamic asyncValue) {
    final rng = Random();
    return factsAsync.maybeWhen(
      data: (facts) {
        if (facts is List && facts.isNotEmpty) {
          final picked = facts[rng.nextInt(facts.length)];
          // FunFactModel.content
          try {
            return picked.content as String;
          } catch (_) {
            return _fallbackFacts[rng.nextInt(_fallbackFacts.length)];
          }
        }
        return _fallbackFacts[rng.nextInt(_fallbackFacts.length)];
      },
      orElse: () => _fallbackFacts[rng.nextInt(_fallbackFacts.length)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = factsAsync.isLoading;
    final factText = isLoading ? null : _pickFact(factsAsync);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.accentCardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 22,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_rounded, color: AppColors.warn, size: 24),
              SizedBox(width: 8),
              Text(
                'Fun Fact Checkpoint',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'SDG 4 — Quality Education',
              style: TextStyle(
                color: AppColors.warn,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            )
          else
            Text(
              factText ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}
