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
/// Pop-up overlay yang menampilkan fakta edukatif SDG 4 setiap kali player
/// mencapai checkpoint (kelipatan skor). Fakta di-generate oleh AI (Gemini)
/// secara real-time. Game di-pause selama overlay ditampilkan.

class FunFactOverlay extends ConsumerStatefulWidget {
  /// Reference ke GameWorld untuk resume game setelah overlay ditutup.
  final GameWorld game;

  const FunFactOverlay({super.key, required this.game});

  @override
  ConsumerState<FunFactOverlay> createState() => _FunFactOverlayState();
}

class _FunFactOverlayState extends ConsumerState<FunFactOverlay> {
  /// Checkpoint yang faktanya sudah disimpan ke koleksi — mencegah
  /// collectFact dipanggil berulang tiap kali overlay ter-rebuild.
  int? _savedCheckpoint;

  @override
  Widget build(BuildContext context) {
    // Nomor checkpoint aktif → memicu fakta AI baru pada tiap checkpoint.
    final checkpoint = ref.watch(factCheckpointProvider);
    final factAsync = ref.watch(aiFunFactProvider(checkpoint));

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
                  Icon(Icons.science, color: AppColors.warn, size: 28),
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

              // Science badge (SDG 4 — Quality Education)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🔬 Science Fun Fact',
                  style: TextStyle(
                    color: AppColors.warn,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─── Fact Content (AI-generated) ──────────────
              factAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.warn),
                      SizedBox(height: 12),
                      Text(
                        'Generating a fun fact...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                error: (error, _) => Text(
                  'Failed to load fact: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.danger),
                ),
                data: (fact) {
                  // Simpan fakta AI ke koleksi user — HANYA sekali per
                  // checkpoint. Tanpa guard ini, tiap rebuild overlay memicu
                  // read Firestore yang sia-sia (collectFact akhirnya skip).
                  if (_savedCheckpoint != checkpoint) {
                    _savedCheckpoint = checkpoint;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final uid = ref.read(currentUserUidProvider);
                      if (uid != null) {
                        // CRUD: CREATE — masuk subcollection collected_facts.
                        ref
                            .read(collectedFactServiceProvider)
                            .collectFact(uid, fact);
                      }
                    });
                  }

                  return Text(
                    fact.content,
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
              // Nonaktif saat fakta masih di-generate, agar pemain tidak
              // skip sebelum fakta sempat tampil & tersimpan ke koleksi.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: factAsync.isLoading
                      ? null
                      : () => widget.game.resumeFromFunFact(),
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
