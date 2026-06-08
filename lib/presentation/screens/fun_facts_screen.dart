import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../models/collected_fact_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collected_fact_provider.dart';
import '../../providers/ui_language_provider.dart';
import '../widgets/state_views.dart';

/// ═══════════════════════════════════════
/// FUN FACTS SCREEN — JumPedia
/// ═══════════════════════════════════════
/// Halaman koleksi fakta IPA yang sudah didapatkan pemain selama bermain.
/// Setiap fakta di-generate AI saat checkpoint, lalu disimpan ke koleksi
/// pribadi user (users/{uid}/collected_facts). Halaman ini menampilkan
/// koleksi tersebut sebagai grid 2 kolom.
///
/// CRUD di-handle via CollectedFactService:
/// - CREATE: dari [fun_fact_overlay.dart] saat fakta AI muncul di game
/// - READ:   stream `collectedFactsStreamProvider` di sini
/// - DELETE: tombol hapus per-item + tombol reset semua di header
/// Pemain TIDAK boleh mengedit isi fakta (konten edukasi harus tetap utuh).

class FunFactsScreen extends ConsumerWidget {
  const FunFactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectedAsync = ref.watch(collectedFactsStreamProvider);
    final s = ref.watch(uiStringsProvider);

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.funFactsCollection,
                          style: const TextStyle(
                            color: AppColors.textHi,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          s.funFactsCollectionDesc,
                          style: const TextStyle(
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
                    tooltip: s.resetCollection,
                    icon: const Icon(Icons.delete_sweep_rounded,
                        color: AppColors.danger),
                    onPressed: () => _confirmResetAll(context, ref),
                  ),
                ],
              ),
            ),

            // ─── Counter koleksi ─────────────────
            _CollectionCounter(collectedAsync: collectedAsync, label: s.factsCollected),

            const SizedBox(height: 12),

            // ─── Grid ────────────────────────────
            Expanded(
              child: collectedAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(message: '${s.error}: $e'),
                data: (collected) {
                  if (collected.isEmpty) {
                    return _EmptyState(message: s.noFactsYet);
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: collected.length,
                    itemBuilder: (context, i) {
                      final fact = collected[i];
                      return _FactCard(
                        index: i,
                        fact: fact,
                        onTap: () => _openDetail(context, ref, fact),
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
    CollectedFactModel fact,
  ) async {
    final s = ref.read(uiStringsProvider);
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
                  const Icon(Icons.science_rounded, color: AppColors.warn),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.scienceFunFact,
                      style: const TextStyle(
                        color: AppColors.textHi,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  // UPDATE — toggle favorite (tidak mengubah isi fakta).
                  IconButton(
                    tooltip:
                        fact.isFavorite ? 'Remove favorite' : 'Mark as favorite',
                    icon: Icon(
                      fact.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.warn,
                    ),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _toggleFavorite(context, ref, fact);
                    },
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
                fact.content,
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
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _deleteOne(context, ref, fact.factId);
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 18),
                    label: Text(
                      s.delete,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      s.close,
                      style: const TextStyle(color: AppColors.textLo),
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

  // ─── UPDATE — toggle favorit (tanpa mengubah isi fakta) ─
  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    CollectedFactModel fact,
  ) async {
    final uid = ref.read(currentUserUidProvider);
    if (uid == null) return;
    final newValue = !fact.isFavorite;
    try {
      await ref.read(collectedFactServiceProvider).setFavorite(
            uid,
            factId: fact.factId,
            isFavorite: newValue,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newValue ? 'Added to favorites ⭐' : 'Removed from favorites',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
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
    final s = ref.read(uiStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgMid,
        title: Text(
          s.resetCollection,
          style: const TextStyle(color: AppColors.textHi),
        ),
        content: Text(
          s.resetCollectionDesc,
          style: const TextStyle(color: AppColors.textLo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel,
                style: const TextStyle(color: AppColors.textLo)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.reset,
                style: const TextStyle(color: AppColors.danger)),
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

// ─── Counter koleksi di atas grid ──────────────────────
class _CollectionCounter extends StatelessWidget {
  final AsyncValue<List<CollectedFactModel>> collectedAsync;
  final String label;
  const _CollectionCounter({required this.collectedAsync, required this.label});

  @override
  Widget build(BuildContext context) {
    final got = collectedAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

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
      child: Row(
        children: [
          const Icon(Icons.auto_stories_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textLo,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Text(
            '$got',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card untuk tiap fakta yang sudah dikoleksi ────────
class _FactCard extends StatelessWidget {
  final int index;
  final CollectedFactModel fact;
  final VoidCallback onTap;

  const _FactCard({
    required this.index,
    required this.fact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.warn.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: AppColors.warn,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (fact.isFavorite)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.star_rounded,
                        color: AppColors.warn,
                        size: 18,
                      ),
                    ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  fact.content,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fact.category,
                  style: const TextStyle(
                    color: Colors.white,
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
  final String message;
  const _EmptyState({required this.message});

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
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textHi,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
