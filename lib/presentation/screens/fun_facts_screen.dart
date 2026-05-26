import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../models/collected_fact_model.dart';
import '../../models/fun_fact_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collected_fact_provider.dart';
import '../../providers/fun_fact_provider.dart';

/// ═══════════════════════════════════════
/// FUN FACTS SCREEN — JumPedia
/// ═══════════════════════════════════════
/// Halaman koleksi fakta yang sudah didapatkan pemain selama bermain.
/// Tampilan grid 2 kolom — card berwarna jika sudah dikoleksi, card "???"
/// abu-abu jika belum. Tap card untuk membuka detail.
///
/// CRUD lengkap di-handle via CollectedFactService:
/// - CREATE: dari [fun_fact_overlay.dart] saat fact muncul di game
/// - READ:   stream `collectedFactsStreamProvider` di sini
/// - UPDATE: dialog "Refresh" di detail card (snap ulang content)
/// - DELETE: tombol hapus per-item + tombol reset semua di app bar

class FunFactsScreen extends ConsumerWidget {
  const FunFactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allFactsAsync = ref.watch(allFunFactsProvider);
    final collectedAsync = ref.watch(collectedFactsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header (judul + ilustrasi inline) ─
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
              child: Row(
                children: [
                  // Ilustrasi mascot kecil di kiri header.
                  Image.asset(
                    'assets/images/fact_illustration.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                    cacheWidth: 168,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Fun Facts Collection',
                          style: TextStyle(
                            color: AppColors.textHi,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Collect SDG 4 facts at every checkpoint',
                          style: TextStyle(
                            color: AppColors.textLo,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Reset all — DELETE batch
                  IconButton(
                    tooltip: 'Reset collection',
                    icon: const Icon(Icons.delete_sweep_rounded,
                        color: AppColors.danger),
                    onPressed: () => _confirmResetAll(context, ref),
                  ),
                ],
              ),
            ),

            // ─── Progress Bar ───────────────────
            _ProgressBar(
              allFactsAsync: allFactsAsync,
              collectedAsync: collectedAsync,
            ),

            const SizedBox(height: 12),

            // ─── Grid ────────────────────────────
            Expanded(
              child: allFactsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Failed to load facts:\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textLo),
                    ),
                  ),
                ),
                data: (allFacts) {
                  if (allFacts.isEmpty) {
                    return const _EmptyState();
                  }

                  final collected = collectedAsync.maybeWhen(
                    data: (list) => list,
                    orElse: () => const <CollectedFactModel>[],
                  );
                  final collectedMap = {
                    for (final c in collected) c.factId: c,
                  };

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: allFacts.length,
                    itemBuilder: (context, i) {
                      final fact = allFacts[i];
                      final got = collectedMap[fact.factId];
                      return _FactCard(
                        index: i,
                        fact: fact,
                        collected: got,
                        onTap: () => _openDetail(context, ref, fact, got),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // Detail dialog — UPDATE & DELETE entry point
  // ═══════════════════════════════════════
  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    FunFactModel fact,
    CollectedFactModel? collected,
  ) async {
    final isCollected = collected != null;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bgMid,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCollected
                        ? Icons.school_rounded
                        : Icons.lock_outline_rounded,
                    color: isCollected ? AppColors.warn : AppColors.textLo,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCollected ? 'Collected Fact' : 'Not Yet Collected',
                      style: const TextStyle(
                        color: AppColors.textHi,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  fact.category.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isCollected
                    ? (collected.content)
                    : 'Play the game and reach checkpoints to unlock this fact! 🚀',
                style: const TextStyle(
                  color: AppColors.textHi,
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isCollected) ...[
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _refreshFact(context, ref, fact);
                      },
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.cyanAccent, size: 18),
                      label: const Text(
                        'Refresh',
                        style: TextStyle(color: Colors.cyanAccent),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _deleteOne(context, ref, fact.factId);
                      },
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 18),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── UPDATE — sync isi snapshot dari koleksi master ─────
  Future<void> _refreshFact(
    BuildContext context,
    WidgetRef ref,
    FunFactModel fact,
  ) async {
    final uid = ref.read(currentUserUidProvider);
    if (uid == null) return;
    try {
      await ref.read(collectedFactServiceProvider).updateCollectedFact(
            uid,
            factId: fact.factId,
            newContent: fact.content,
            newCategory: fact.category,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fact refreshed successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refresh failed: $e')),
        );
      }
    }
  }

  // ─── DELETE single ────────────────────────────────────
  Future<void> _deleteOne(
    BuildContext context,
    WidgetRef ref,
    String factId,
  ) async {
    final uid = ref.read(currentUserUidProvider);
    if (uid == null) return;
    try {
      await ref
          .read(collectedFactServiceProvider)
          .deleteCollectedFact(uid, factId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fact removed from collection')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  // ─── DELETE batch ─────────────────────────────────────
  Future<void> _confirmResetAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgMid,
        title: const Text(
          'Reset Collection?',
          style: TextStyle(color: AppColors.textHi),
        ),
        content: const Text(
          'All facts you have collected will be deleted. '
          'This action cannot be undone.',
          style: TextStyle(color: AppColors.textLo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textLo)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final uid = ref.read(currentUserUidProvider);
    if (uid == null) return;
    try {
      await ref
          .read(collectedFactServiceProvider)
          .clearAllCollectedFacts(uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection reset successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
    }
  }
}

// ─── Progress bar di atas grid ─────────────────────────
class _ProgressBar extends StatelessWidget {
  final AsyncValue<List<FunFactModel>> allFactsAsync;
  final AsyncValue<List<CollectedFactModel>> collectedAsync;
  const _ProgressBar({
    required this.allFactsAsync,
    required this.collectedAsync,
  });

  @override
  Widget build(BuildContext context) {
    final total = allFactsAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );
    final got = collectedAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );
    final progress = total == 0 ? 0.0 : (got / total).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgMid,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  color: AppColors.textLo,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '$got / $total facts',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card untuk tiap fact (collected / locked) ────────
class _FactCard extends StatelessWidget {
  final int index;
  final FunFactModel fact;
  final CollectedFactModel? collected;
  final VoidCallback onTap;

  const _FactCard({
    required this.index,
    required this.fact,
    required this.collected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCollected = collected != null;

    // Card collected: gradient biru penuh. Card locked: putih bersih.
    final Decoration decoration = isCollected
        ? BoxDecoration(
            gradient: AppColors.accentCardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          )
        : BoxDecoration(
            color: AppColors.bgMid,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.2),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: decoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCollected
                          ? AppColors.warn.withValues(alpha: 0.25)
                          : AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: isCollected ? AppColors.warn : AppColors.primary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isCollected
                        ? Icons.check_circle_rounded
                        : Icons.lock_rounded,
                    color: isCollected ? Colors.white : AppColors.textLo,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  isCollected
                      ? collected!.content
                      : '???\nMain untuk membuka fakta ini.',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCollected ? Colors.white : AppColors.textLo,
                    fontSize: 12,
                    height: 1.35,
                    fontStyle:
                        isCollected ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isCollected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fact.category,
                  style: TextStyle(
                    color: isCollected ? Colors.white : AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/fact_illustration.png',
              height: 200,
              fit: BoxFit.contain,
              cacheWidth: 540,
            ),
            const SizedBox(height: 16),
            const Text(
              'No facts available yet',
              style: TextStyle(
                color: AppColors.textHi,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add documents to the fun_facts collection via Firebase Console.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textLo,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
