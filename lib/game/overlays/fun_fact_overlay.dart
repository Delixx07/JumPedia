import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/fun_fact_provider.dart';
import '../world/game_world.dart';

/// ═══════════════════════════════════════
/// FUN FACT OVERLAY — SDG Eco-Jump
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B5E20), // Dark green
                Color(0xFF2E7D32), // Green
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: Colors.greenAccent.withValues(alpha: 0.5),
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
                  Icon(Icons.school, color: Colors.amber, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Tahukah Kamu?',
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
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SDG 4 — Pendidikan Berkualitas',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─── Fact Content ──────────────
              factsAsync.when(
                loading: () => const CircularProgressIndicator(
                  color: Colors.greenAccent,
                ),
                error: (error, _) => Text(
                  'Gagal memuat fakta: $error',
                  style: const TextStyle(color: Colors.red),
                ),
                data: (facts) {
                  if (facts.isEmpty) {
                    return const Text(
                      '258 juta anak dan remaja di seluruh dunia '
                      'masih tidak bersekolah. Pendidikan berkualitas '
                      'adalah kunci untuk masa depan yang lebih baik!',
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

                  // Tandai sebagai sudah ditampilkan
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref
                        .read(shownFactsProvider.notifier)
                        .markAsShown(factToShow.factId);
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
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Lanjut Main! 🚀',
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
