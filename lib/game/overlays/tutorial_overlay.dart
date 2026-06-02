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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lightbulb_rounded,
                        color: AppColors.warn, size: 26),
                    SizedBox(width: 8),
                    Text(
                      'How to Play',
                      style: TextStyle(
                        color: AppColors.textHi,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bounce up, collect items, and learn!',
                  style: TextStyle(color: AppColors.textLo, fontSize: 12.5),
                ),
                const SizedBox(height: 18),

                // ─── Item: Buku & Pensil ─────────
                const _TutorialItem(
                  imagePaths: [
                    'assets/collectibles/book.png',
                    'assets/collectibles/pencil.png',
                  ],
                  title: 'Books & Pencils',
                  desc: '+${AppConstants.bookPoints} points each. '
                      'Collect them to boost your score!',
                ),
                const SizedBox(height: 12),

                // ─── Item: Globe ─────────────────
                const _TutorialItem(
                  imagePaths: ['assets/collectibles/globe.png'],
                  title: 'Globe',
                  desc: 'Gives a shield or a speed boost for a few seconds. '
                      'Grab it for power-ups!',
                ),
                const SizedBox(height: 12),

                // ─── Item: Sampah / Obstacle (semua bentuk) ─────
                const _TutorialItem(
                  imagePaths: [
                    'assets/images/obstacle/botol_plastik.png',
                    'assets/images/obstacle/botol_kaleng.png',
                    'assets/images/obstacle/kantong_plastik.png',
                  ],
                  title: 'Trash (Obstacles)',
                  desc: 'Avoid all trash — each hit costs a heart '
                      '(unless you have a shield).',
                ),
                const SizedBox(height: 12),

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

/// Baris item tutorial: menampilkan SEMUA varian gambar + judul + deskripsi.
class _TutorialItem extends StatelessWidget {
  /// Satu atau lebih path gambar varian item (mis. semua jenis sampah).
  final List<String> imagePaths;
  final String title;
  final String desc;

  const _TutorialItem({
    required this.imagePaths,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Deretan semua varian gambar.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final path in imagePaths)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.scaffold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(path, fit: BoxFit.contain),
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(child: _itemText(title, desc)),
      ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.scaffold,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(child: _itemText(title, desc)),
      ],
    );
  }
}

/// Teks judul + deskripsi (dipakai bersama oleh kedua jenis item).
Widget _itemText(String title, String desc) {
  return Column(
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
      const SizedBox(height: 2),
      Text(
        desc,
        style: const TextStyle(
          color: AppColors.textLo,
          fontSize: 12,
          height: 1.35,
        ),
      ),
    ],
  );
}
