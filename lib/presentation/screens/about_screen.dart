import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/ui_language_provider.dart';

/// ═══════════════════════════════════════
/// ABOUT SCREEN — JumPedia
/// ═══════════════════════════════════════
/// Info aplikasi: versi, deskripsi, SDG 4 yang diangkat, dan kredit tim.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  /// Versi app (selaras dengan pubspec.yaml version).
  static const String _version = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(uiStringsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppColors.scaffold),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconButton(
                    onPressed: () => context.go('/settings'),
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.textHi),
                  ),
                  Text(s.aboutTitle,
                      style: const TextStyle(
                          color: AppColors.textHi,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 16),

                // ─── Logo + versi ─────────────────
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo_jumpedia.png',
                        height: 104,
                        fit: BoxFit.contain,
                        cacheWidth: 800,
                      ),
                      const SizedBox(height: 8),
                      Text(s.appVersion(_version),
                          style: const TextStyle(
                              color: AppColors.textLo, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(s.aboutDescription,
                    style: const TextStyle(
                        color: AppColors.textHi, fontSize: 14, height: 1.5)),
                const SizedBox(height: 28),

                // ─── SDG 4 card ───────────────────
                _SectionTitle(s.sdgTitle),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgMid,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC5192D), // warna SDG 4
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('4',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.sdg4,
                                style: const TextStyle(
                                    color: AppColors.textHi,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(s.sdg4Desc,
                                style: const TextStyle(
                                    color: AppColors.textLo,
                                    fontSize: 12,
                                    height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ─── Credits ──────────────────────
                _SectionTitle(s.creditsTitle),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.groups_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(s.teamName,
                      style: const TextStyle(
                          color: AppColors.textHi,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.favorite_rounded,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 12),
                  Text(s.madeWith,
                      style: const TextStyle(
                          color: AppColors.textLo, fontSize: 13)),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0));
  }
}
