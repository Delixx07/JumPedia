import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// ═══════════════════════════════════════
/// TUTORIAL OVERLAY — JumPedia
/// ═══════════════════════════════════════
/// Pop-up yang muncul sebelum game dimulai. Menjelaskan fungsi tiap item
/// (buku, globe, sampah) dan memberi tahu bahwa setiap kelipatan skor
/// tertentu pemain mendapat fun fact IPA.
///
/// Game di-pause selama tutorial tampil; tombol "Mulai!" memanggil [onStart].

class TutorialOverlay extends StatelessWidget {
  /// Dipanggil saat pemain menekan tombol "Mulai!".
  final VoidCallback onStart;

  const TutorialOverlay({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.bgMid,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Header ──────────────────────
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lightbulb_rounded,
                      color: AppColors.warn, size: 30),
                ),
                const SizedBox(height: 10),
                const Text(
                  'How to Play',
                  style: TextStyle(
                    color: AppColors.textHi,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Bounce up, collect items, and learn!',
                  style: TextStyle(color: AppColors.textLo, fontSize: 12.5),
                ),
                const SizedBox(height: 18),

                // ─── Item: Buku ──────────────────
                const _TutorialItem(
                  imagePaths: ['assets/collectibles/book/book.png'],
                  title: 'Books',
                  desc: '+${AppConstants.bookPoints} points each — '
                      'collect them to grow your knowledge & score!',
                  accent: AppColors.primary,
                ),
                const SizedBox(height: 10),

                // ─── Item: Globe ─────────────────
                const _TutorialItem(
                  imagePaths: ['assets/collectibles/globe/globe.png'],
                  title: 'Globe',
                  desc: 'Gives a protective shield for a few seconds.',
                  accent: AppColors.primary,
                ),
                const SizedBox(height: 10),

                // ─── Item: Robot AI (obstacle bertema) ─────
                const _TutorialItem(
                  imagePaths: ['assets/images/obstacle/obstacle_ai.png'],
                  title: 'Lazy-Thinking AI',
                  desc: 'Relying on AI to think for you makes your mind lazy. '
                      'Dodge it — each hit costs a heart (unless shielded).',
                  accent: AppColors.danger,
                ),
                const SizedBox(height: 10),

                // ─── HP / Hearts ─────────────────
                const _TutorialIconItem(
                  icon: Icons.favorite_rounded,
                  iconColor: AppColors.danger,
                  title: '${AppConstants.initialHp} Hearts',
                  desc: 'You start with ${AppConstants.initialHp} hearts. '
                      'Lose them all and it\'s game over!',
                ),
                const SizedBox(height: 16),

                // ─── Fun fact info banner ────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentCardGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.science_rounded,
                          color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(text: 'Every '),
                              TextSpan(
                                text: '${AppConstants.funFactScoreInterval} '
                                    'points',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(
                                text: ' you unlock a fun science fact to '
                                    'collect! 🔬',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Start button ────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Start! 🚀',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu pembungkus tiap baris item — background lembut + garis aksen kiri.
class _ItemCard extends StatelessWidget {
  final Color accent;
  final Widget leading;
  final String title;
  final String desc;

  const _ItemCard({
    required this.accent,
    required this.leading,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.scaffold.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: accent, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textHi,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textLo,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris item tutorial: menampilkan SEMUA varian gambar + judul + deskripsi.
class _TutorialItem extends StatelessWidget {
  /// Satu atau lebih path gambar varian item (mis. semua jenis sampah).
  final List<String> imagePaths;
  final String title;
  final String desc;
  final Color accent;

  const _TutorialItem({
    required this.imagePaths,
    required this.title,
    required this.desc,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return _ItemCard(
      accent: accent,
      title: title,
      desc: desc,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final path in imagePaths)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Image.asset(path, fit: BoxFit.contain),
              ),
            ),
        ],
      ),
    );
  }
}

/// Baris item tutorial dengan ikon (untuk HP).
class _TutorialIconItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;

  const _TutorialIconItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return _ItemCard(
      accent: iconColor,
      title: title,
      desc: desc,
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }
}
