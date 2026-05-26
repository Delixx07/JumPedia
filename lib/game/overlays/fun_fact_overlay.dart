import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collected_fact_provider.dart';
import '../../providers/fun_fact_provider.dart';
import '../world/game_world.dart';

/// ═══════════════════════════════════════
/// FUN FACT OVERLAY — JumPedia
/// ═══════════════════════════════════════
/// Pop-up overlay yang menampilkan fakta edukatif SDG 4
/// setiap kali player mencapai ketinggian 500 unit.
/// Game di-pause selama overlay ditampilkan.

class FunFactOverlay extends ConsumerWidget {
  /// Reference ke GameWorld untuk resume game setelah overlay ditutup.
  final GameWorld game;

  const FunFactOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factsAsync = ref.watch(allFunFactsProvider);

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.accentCardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.5),
                blurRadius: 28,
                spreadRadius: 6,
              ),
            ],
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Header ────────────────────
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, color: AppColors.warn, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Did You Know?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // SDG 4 Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SDG 4 — Quality Education',
                  style: TextStyle(
                    color: AppColors.warn,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─── Fact Content ──────────────
              factsAsync.when(
                loading: () => const CircularProgressIndicator(
                  color: AppColors.warn,
                ),
                error: (error, _) => Text(
                  'Failed to load facts: $error',
                  style: const TextStyle(color: AppColors.danger),
                ),
                data: (facts) {
                  if (facts.isEmpty) {
                    return const Text(
                      '258 million children and young people around the world '
                      'are still out of school. Quality education is the key '
                      'to a better future!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    );
                  }

                  // Ambil fakta yang belum ditampilkan
                  final shownFacts = ref.read(shownFactsProvider);
                  final unshownFacts = facts
                      .where((f) => !shownFacts.contains(f.factId))
                      .toList();

                  final factToShow = unshownFacts.isNotEmpty
                      ? (unshownFacts..shuffle()).first
                      : (facts..shuffle()).first;

                  // Tandai sebagai sudah ditampilkan + simpan ke koleksi user.
                  // CRUD: CREATE — fact ini masuk subcollection collected_facts.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref
                        .read(shownFactsProvider.notifier)
                        .markAsShown(factToShow.factId);

                    final uid = ref.read(currentUserUidProvider);
                    if (uid != null) {
                      ref
                          .read(collectedFactServiceProvider)
                          .collectFact(uid, factToShow);
                    }
                  });

                  return Text(
                    factToShow.content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // ─── Continue Button ───────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    game.resumeFromFunFact();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warn,
                    foregroundColor: AppColors.bgTop,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Keep Playing! 🚀',
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
    );
  }
}
