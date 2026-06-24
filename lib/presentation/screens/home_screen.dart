import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ui_language_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/state_views.dart';
import '../../services/score_service.dart';
import '../../services/user_service.dart';
import '../../services/audio_service.dart';
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

  // Pastikan leaderboard user sinkron dengan riwayat sebelum menampilkan
  // statistik di dashboard (manual sync untuk menghindari inkonsistensi
  // ketika user menghapus riwayat dari UI).
  await scoreService.syncUserLeaderboardFromHistory(uid);

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
final _currentUserModelProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final uid = ref.watch(currentUserUidProvider);
  if (uid == null) return Stream.value(null);
  final userService = UserService();
  return userService.streamUser(uid);
});

// State to indicate if a linking operation is in progress.
// (Moved to profile_screen.dart or removed if not needed)

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_dashboardStatsProvider);
    final s = ref.watch(uiStringsProvider);
    
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

                  // ─── Hero Mascot ──────────────────────
                  // Mascot 3D karakter brand JumPedia. Pakai cacheWidth
                  // supaya asset 6250px tidak menghabiskan memori.
                  Image.asset(
                    'assets/images/dashboard_hero.png',
                    height: 180,
                    fit: BoxFit.contain,
                    cacheWidth: 480,
                  ),

                  // Logo ditarik ke atas untuk menutup ruang kosong transparan
                  // di bawah gambar mascot, agar tidak terlihat ada celah.
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Image.asset(
                      'assets/images/logo_jumpedia.png',
                      width: 300, // logo brand diukur dari LEBAR (bukan tinggi)
                      fit: BoxFit.contain,
                      cacheWidth: 1000,
                    ),
                  ),

                  // Jarak ke stats dikecilkan untuk mengompensasi geser -48
                  // pada logo (Transform.translate menyisakan ruang aslinya).
                  const SizedBox(height: 0),

                  // ─── Stats Cards ──────────────────────
                  _StatsRow(
                    statsAsync: statsAsync,
                    s: s,
                  ),

                  const SizedBox(height: 24),

                  // ─── Menu Buttons ─────────────────────
                  SdgButton(
                    text: s.startPlaying,
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => context.go('/game'),
                  ),

                  const SizedBox(height: 12),

                  SdgButton(
                    text: s.leaderboard,
                    icon: Icons.leaderboard_rounded,
                    style: SdgButtonStyle.secondary,
                    onPressed: () => context.go('/leaderboard'),
                  ),

                  const SizedBox(height: 12),

                  SdgButton(
                    text: s.settings,
                    icon: Icons.settings_rounded,
                    style: SdgButtonStyle.secondary,
                    onPressed: () => context.go('/settings'),
                  ),

                  const SizedBox(height: 12),

                  SdgButton(
                    text: s.scoreHistory,
                    icon: Icons.history_rounded,
                    style: SdgButtonStyle.secondary,
                    onPressed: () => context.go('/score-history'),
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
    final s = ref.watch(uiStringsProvider);
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
                // Foto kustom (Supabase) jika ada; jika tidak, avatar bawaan.
                backgroundImage: (user?.photoUrl != null &&
                        user!.photoUrl!.isNotEmpty)
                    ? NetworkImage(user.photoUrl!)
                    : AssetImage(
                            'assets/images/avatars/${user?.avatarPath ?? 'panda.png'}')
                        as ImageProvider,
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.settingUpProfile,
                      style: const TextStyle(
                          color: AppColors.textHi,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(s.justAMoment,
                        style: const TextStyle(
                            color: AppColors.textLo, fontSize: 12)),
                  ],
                );
              }
              final name = user.username;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.greeting(name),
                    style: const TextStyle(
                      color: AppColors.textHi,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    s.homeSubtitle,
                    style: const TextStyle(
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
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
              ],
            ),
            error: (_, __) => Text(s.greeting(s.player),
                style: const TextStyle(
                    color: AppColors.textHi,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        IconButton(
          tooltip: s.logout,
          icon: const Icon(Icons.logout_rounded, color: AppColors.textLo),
          onPressed: () async {
            final authUser = ref.read(authStateProvider).value;
            final isAnon = authUser?.isAnonymous ?? false;

            if (isAnon) {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(s.logout),
                  content: Text('${s.guestNoProgress}\n\n${s.guestAccountDesc}'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(s.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        s.logout,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;
            }

            final authService = ref.read(authServiceProvider);
            // Stop background music immediately on logout.
            await AudioService.stopBgm();
            await authService.signOut();
            if (context.mounted) context.go('/login');
          },
        ),
      ],
    );
  }
}

/// Baris yang menampilkan 2 kartu statistik: best score & total games.
class _StatsRow extends ConsumerWidget {
  final AsyncValue<_DashboardStats?> statsAsync;
  final AppStrings s;

  const _StatsRow({
    required this.statsAsync,
    required this.s,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                label: s.bestScore,
                value: best.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.sports_esports_rounded,
                color: AppColors.accent,
                label: s.gamesPlayed,
                value: games.toString(),
              ),
            ),
          ],
        );
      },
      loading: () => const _StatsRowSkeleton(),
      error: (_, __) => Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.emoji_events_rounded,
              color: AppColors.warn,
              label: s.bestScore,
              value: '—',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.sports_esports_rounded,
              color: AppColors.accent,
              label: s.gamesPlayed,
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
    return const Row(
      children: [
        Expanded(child: SkeletonBox(height: 84)),
        SizedBox(width: 12),
        Expanded(child: SkeletonBox(height: 84)),
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
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      borderColor: color.withValues(alpha: 0.45),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          // Label + value. Expanded agar mengisi sisa ruang; ikon hapus
          // (trailing) berada SETELAH ini, bukan menumpuk di atasnya.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textLo,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppColors.textHi,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
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
