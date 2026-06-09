import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/score_history_model.dart';
import '../../providers/score_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ui_language_provider.dart';
import '../widgets/state_views.dart';

class ScoreHistoryScreen extends ConsumerStatefulWidget {
  const ScoreHistoryScreen({super.key});

  @override
  ConsumerState<ScoreHistoryScreen> createState() => _ScoreHistoryScreenState();
}

class _ScoreHistoryScreenState extends ConsumerState<ScoreHistoryScreen> {
  bool _busy = false;

  Future<void> _confirmDeleteSingle(String uid, ScoreHistoryModel item) async {
    final s = ref.read(uiStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.delete),
        content: Text(s.deleteScoreConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(s.cancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(s.delete)),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(scoreServiceProvider).deleteScoreHistoryItem(uid, item.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(uiStringsProvider).scoreDeleted)),
        );
      }
      ref.invalidate(userScoreHistoryProvider(uid));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDeleteAll(String uid) async {
    final s = ref.read(uiStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.delete),
        content: Text(s.deleteAllScoresConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(s.cancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(s.delete)),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(scoreServiceProvider).deleteAllScoreHistory(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(uiStringsProvider).allScoresDeleted)),
        );
      }
      ref.invalidate(userScoreHistoryProvider(uid));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatTimestamp(ScoreHistoryModel h) {
    final dt = h.timestamp.toDate().toLocal();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(uiStringsProvider);
    final uid = ref.watch(currentUserUidProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.textHi),
                    ),
                    Expanded(
                      child: Text(s.scoreHistory,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textHi,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => ref.invalidate(userScoreHistoryProvider(uid ?? '')),
                          icon: const Icon(Icons.refresh, color: AppColors.textHi),
                        ),
                        IconButton(
                          tooltip: s.delete,
                          icon: const Icon(Icons.delete_forever, color: AppColors.textHi),
                          onPressed: (uid == null || _busy) ? null : () => _confirmDeleteAll(uid),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: uid == null
                    ? Center(child: Text(s.googleOnlyDesc))
                    : ref.watch(userScoreHistoryProvider(uid)).when(
                          loading: () => const LoadingView(),
                          error: (e, _) => ErrorView(
                            message: '${s.error}: $e',
                            onRetry: () => ref.invalidate(userScoreHistoryProvider(uid)),
                          ),
                          data: (list) {
                            if (list.isEmpty) {
                              return EmptyView(
                                icon: Icons.history_toggle_off,
                                title: s.noScoreHistory,
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                final item = list[i];
                                final rank = i + 1;
                                final rankColor = rank == 1
                                    ? const Color(0xFFFFB300)
                                    : rank == 2
                                        ? const Color(0xFF9E9E9E)
                                        : rank == 3
                                            ? const Color(0xFFB87333)
                                            : AppColors.textLo;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgMid,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: rankColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(children: [
                                    Text('#$rank', style: TextStyle(color: rankColor, fontSize: 16, fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        _formatTimestamp(item),
                                        style: const TextStyle(color: AppColors.textHi, fontSize: 16),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${item.score}', style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w800)),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                          onPressed: _busy ? null : () => _confirmDeleteSingle(uid, item),
                                        ),
                                      ],
                                    ),
                                  ]),
                                );
                              },
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
