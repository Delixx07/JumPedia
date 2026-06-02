import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/score_provider.dart';
import '../widgets/sdg_button.dart';

/// ═══════════════════════════════════════
/// GAME OVER SCREEN — JumPedia
/// ═══════════════════════════════════════
/// Ditampilkan setelah player meninggal (HP = 0 atau jatuh).
/// Menampilkan skor akhir dan opsi Restart (main lagi) atau Back Home.

class GameOverScreen extends ConsumerWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finalScore = ref.read(scoreProvider);

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

                const SizedBox(height: 28),

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
