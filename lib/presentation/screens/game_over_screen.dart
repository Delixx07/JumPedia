import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/score_provider.dart';
import '../widgets/sdg_button.dart';

/// Game Over Screen — Ditampilkan setelah game over.
class GameOverScreen extends ConsumerWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finalScore = ref.read(scoreProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                const Text('GAME OVER', style: TextStyle(color: Colors.redAccent, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 4)),
                const SizedBox(height: 8),
                Text('Perjalananmu berakhir di sini...', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF162447)]),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 48),
                      const SizedBox(height: 12),
                      const Text('SKOR AKHIR', style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(finalScore.toString(), style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                SdgButton(text: 'Main Lagi', icon: Icons.refresh_rounded, onPressed: () => context.go('/game')),
                const SizedBox(height: 12),
                SdgButton(text: 'Lihat Leaderboard', icon: Icons.leaderboard_rounded, style: SdgButtonStyle.secondary, onPressed: () => context.go('/leaderboard')),
                const SizedBox(height: 12),
                TextButton(onPressed: () => context.go('/home'), child: Text('Kembali ke Menu', style: TextStyle(color: Colors.white.withValues(alpha: 0.6)))),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
