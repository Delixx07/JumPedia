import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/hp_provider.dart';
import '../../providers/score_provider.dart';

/// ═══════════════════════════════════════
/// HUD OVERLAY — JumPedia
/// ═══════════════════════════════════════
/// Overlay yang menampilkan HP bar dan skor secara real-time di atas game.
/// Menggunakan ref.watch untuk update otomatis dari Riverpod.

class HudOverlay extends ConsumerWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch skor dan HP secara real-time
    final score = ref.watch(scoreProvider);
    final hp = ref.watch(hpProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ─── HP Bar ──────────────────────
            _buildHpBar(hp),

            // ─── Score Display ───────────────
            _buildScoreDisplay(score),
          ],
        ),
      ),
    );
  }

  /// Widget HP bar dengan ikon hati.
  Widget _buildHpBar(int hp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Render hati berdasarkan HP saat ini
          ...List.generate(AppConstants.maxHp, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                index < hp ? Icons.favorite : Icons.favorite_border,
                color: index < hp
                    ? AppColors.accent
                    : AppColors.accent.withValues(alpha: 0.3),
                size: 20,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Widget display skor.
  Widget _buildScoreDisplay(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.warn.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            color: AppColors.warn,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            score.toString().padLeft(6, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
