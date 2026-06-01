import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/score_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../widgets/sdg_button.dart';

/// ═══════════════════════════════════════
/// HOME SCREEN — JumPedia
/// ═══════════════════════════════════════
/// Dashboard utama: profil singkat, statistik pemain (best score &
/// total games), dan menu navigasi (Play, Leaderboard, Settings, Logout).

/// Bundel statistik yang ditampilkan di dashboard.
class _DashboardStats {
  final int bestScore;
  final int totalGames;

  const _DashboardStats({required this.bestScore, required this.totalGames});
}

/// Provider untuk mengambil statistik dashboard user yang sedang login.
/// Auto-refresh ketika UID berubah (login/logout).
final _dashboardStatsProvider =
    FutureProvider.autoDispose<_DashboardStats?>((ref) async {
  final uid = ref.watch(currentUserUidProvider);
  if (uid == null) return null;

  final scoreService = ScoreService();
  final userService = UserService();

  final bestScoreFuture = scoreService.getUserBestScore(uid);
  final userFuture = userService.getUser(uid);

  final bestScore = await bestScoreFuture;
  final user = await userFuture;

  return _DashboardStats(
    bestScore: bestScore,
    totalGames: user?.totalGamesPlayed ?? 0,
  );
});

/// Stream provider untuk model user saat ini (real-time)
final _currentUserModelProvider =
    StreamProvider.autoDispose<UserModel?>((ref) {
  final uid = ref.watch(currentUserUidProvider);
  if (uid == null) return Stream.value(null);
  final userService = UserService();
  return userService.streamUser(uid);
});

// State to indicate if a linking operation is in progress.
final _isLinkingProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_dashboardStatsProvider);
    final authState = ref.watch(authStateProvider);
    final isAnon = authState.when(
      data: (u) => u?.isAnonymous ?? false,
      loading: () => false,
      error: (_, __) => false,
    );
    final isLinking = ref.watch(_isLinkingProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.heroGradient,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.bgMid,
            onRefresh: () async {
              ref.invalidate(_dashboardStatsProvider);
              await ref.read(_dashboardStatsProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Column(
                children: [
                  // ─── Header: Greeting + Logout ────────
                  const _HeaderBar(),

                  const SizedBox(height: 24),

                  // If the current user is anonymous, show a prompt to link account
                  if (isAnon) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgMid,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your account is guest', style: TextStyle(color: AppColors.textHi, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          const Text('Link to Google to keep your progress across devices.', style: TextStyle(color: AppColors.textLo)),
                          const SizedBox(height: 8),
                          SdgButton(
                            text: 'Link Now with Google',
                            icon: Icons.link,
                            isLoading: isLinking,
                            onPressed: () async {
                              ref.read(_isLinkingProvider.notifier).state = true;
                              try {
                                final authService = ref.read(authServiceProvider);
                                final result = await authService.linkGuestToGoogle();
                                if (result != null) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Account linked successfully!'), backgroundColor: AppColors.success),
                                    );
                                  }
                                }
                              } on FirebaseAuthException catch (e) {
                                if (context.mounted) {
                                  if (e.code == 'credential-already-in-use') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('This Google account is already used by another account.'), backgroundColor: AppColors.danger),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error linking account: ${e.message}'), backgroundColor: AppColors.danger),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error linking account: $e'), backgroundColor: AppColors.danger),
                                  );
                                }
                              } finally {
                                ref.read(_isLinkingProvider.notifier).state = false;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ─── Hero Mascot ──────────────────────
                  // Mascot 3D karakter brand JumPedia. Pakai cacheWidth
                  // supaya asset 6250px tidak menghabiskan memori.
                  Image.asset(
                    'assets/images/dashboard_hero.png',
                    height: 180,
                    fit: BoxFit.contain,
                    cacheWidth: 480,
                  ),

                  const SizedBox(height: 8),

                  // "Jum" biru primary, "Pedia" kuning amber.
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Jum',
                          style: TextStyle(color: AppColors.primary),
                        ),
                        TextSpan(
                          text: 'Pedia',
                          style: TextStyle(color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Jump high, collect knowledge! 📚',
                    style: TextStyle(
                      color: AppColors.textLo,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Stats Cards ──────────────────────
                  _StatsRow(statsAsync: statsAsync),

                  const SizedBox(height: 24),

                  // ─── Menu Buttons ─────────────────────
                  SdgButton(
                    text: 'Start Playing',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => context.go('/game'),
                  ),

                  const SizedBox(height: 12),

                  SdgButton(
                    text: 'Leaderboard',
                    icon: Icons.leaderboard_rounded,
                    style: SdgButtonStyle.secondary,
                    onPressed: () => context.go('/leaderboard'),
                  ),

                  const SizedBox(height: 12),

                  SdgButton(
                    text: 'Settings',
                    icon: Icons.settings_rounded,
                    style: SdgButtonStyle.secondary,
                    onPressed: () => context.go('/settings'),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header bar berisi greeting user + tombol logout.
class _HeaderBar extends ConsumerWidget {
  const _HeaderBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(_currentUserModelProvider);
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: userAsync.when(
            data: (user) => Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.bgMid,
                backgroundImage: AssetImage(
                  'assets/images/avatars/${user?.avatarPath ?? 'panda.png'}',
                ),
              ),
            ),
            loading: () => const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.bgMid,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.bgMid,
              child: Icon(Icons.person),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: userAsync.when(
            data: (user) {
              if (user == null) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setting up profile...',
                      style: TextStyle(color: AppColors.textHi, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text('Just a moment...', style: TextStyle(color: AppColors.textLo, fontSize: 12)),
                  ],
                );
              }
              final name = user.username;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $name',
                    style: const TextStyle(
                      color: AppColors.textHi,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Ready to jump higher today?',
                    style: TextStyle(
                      color: AppColors.textLo,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ],
            ),
            error: (_, __) => const Text('Hello, Player', style: TextStyle(color: AppColors.textHi, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout_rounded, color: AppColors.textLo),
          onPressed: () async {
            final authService = ref.read(authServiceProvider);
            await authService.signOut();
            if (context.mounted) context.go('/login');
          },
        ),
      ],
    );
  }
}

/// Baris yang menampilkan 2 kartu statistik: best score & total games.
class _StatsRow extends StatelessWidget {
  final AsyncValue<_DashboardStats?> statsAsync;
  const _StatsRow({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      data: (stats) {
        final best = stats?.bestScore ?? 0;
        final games = stats?.totalGames ?? 0;
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events_rounded,
                color: AppColors.warn,
                label: 'Best Score',
                value: best.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.sports_esports_rounded,
                color: AppColors.accent,
                label: 'Games Played',
                value: games.toString(),
              ),
            ),
          ],
        );
      },
      loading: () => const _StatsRowSkeleton(),
      error: (_, __) => const Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.emoji_events_rounded,
              color: AppColors.warn,
              label: 'Best Score',
              value: '—',
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.sports_esports_rounded,
              color: AppColors.accent,
              label: 'Total Main',
              value: '—',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRowSkeleton extends StatelessWidget {
  const _StatsRowSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget skel() => Container(
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.bgMid,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        );
    return Row(
      children: [
        Expanded(child: skel()),
        const SizedBox(width: 12),
        Expanded(child: skel()),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textLo,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textHi,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
