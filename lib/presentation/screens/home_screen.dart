import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../widgets/sdg_button.dart';

/// ═══════════════════════════════════════
/// HOME SCREEN — SDG Eco-Jump
/// ═══════════════════════════════════════
/// Menu utama game. Menampilkan tombol-tombol navigasi:
/// Play, Leaderboard, Settings.

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B3A4B),
              Color(0xFF2E7D32),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // ─── Logo & Title ────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 56,
                    color: Colors.greenAccent,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'SDG Eco-Jump',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 4),

                // ─── User Greeting ───────────
                authState.when(
                  data: (user) => Text(
                    'Halo, ${user?.displayName ?? 'Player'}! 👋',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const Spacer(flex: 2),

                // ─── Menu Buttons ────────────

                // PLAY
                SdgButton(
                  text: 'Mulai Bermain',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => context.go('/game'),
                ),

                const SizedBox(height: 16),

                // LEADERBOARD
                SdgButton(
                  text: 'Leaderboard',
                  icon: Icons.leaderboard_rounded,
                  style: SdgButtonStyle.secondary,
                  onPressed: () => context.go('/leaderboard'),
                ),

                const SizedBox(height: 16),

                // SETTINGS
                SdgButton(
                  text: 'Pengaturan',
                  icon: Icons.settings_rounded,
                  style: SdgButtonStyle.secondary,
                  onPressed: () => context.go('/settings'),
                ),

                const Spacer(flex: 2),

                // ─── Footer ──────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🌍 SDG 4 — Pendidikan Berkualitas',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
