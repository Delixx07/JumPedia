import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/logger.dart';
import '../../game/overlays/fun_fact_overlay.dart';
import '../../game/overlays/hud_overlay.dart';
import '../../game/world/game_world.dart';
import '../../providers/hp_provider.dart';
import '../../providers/score_provider.dart';
import '../../providers/fun_fact_provider.dart';
import '../../services/score_service.dart';
import '../../providers/auth_provider.dart';

/// Game Screen — Wrapper untuk GameWidget dari Flame.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late GameWorld _gameWorld;

  @override
  void initState() {
    super.initState();
    // _gameWorld harus diinisialisasi sebelum build() pertama (tidak boleh late uninitialized).
    // Tidak ada Riverpod call di sini — aman dari "modifying provider during build".
    _initializeGame();

    // Reset provider SETELAH frame build selesai, bukan saat build berlangsung.
    // initState() dipanggil selama navigasi (saat widget tree sedang build),
    // sehingga ref.read(...).reset() di sini akan melempar error Riverpod.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(scoreProvider.notifier).resetScore();
      ref.read(hpProvider.notifier).resetHp();
      ref.read(shownFactsProvider.notifier).reset();
    });
  }

  void _initializeGame() {
    _gameWorld = GameWorld(
      ref: ref,
      onGameOver: _handleGameOver,
      showOverlay: (name) {
        _gameWorld.overlays.add(name);
        if (mounted) setState(() {});
      },
      hideOverlay: (name) {
        _gameWorld.overlays.remove(name);
      },
    );
    AppLogger.game('GameScreen initialized');
  }

  void _handleGameOver() async {
    final score = ref.read(scoreProvider);
    final uid = ref.read(currentUserUidProvider);

    if (uid != null) {
      try {
        final scoreService = ScoreService();
        await scoreService.saveScore(uid, score);
        await scoreService.incrementGamesPlayed(uid);
      } catch (e) {
        AppLogger.error('Gagal menyimpan skor', error: e);
      }
    }

    if (mounted) {
      context.go('/game-over');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(
            game: _gameWorld,
            overlayBuilderMap: {
              'hud': (context, game) => const HudOverlay(),
              'funFact': (context, game) => FunFactOverlay(game: game as GameWorld),
            },
            initialActiveOverlays: const ['hud'],
          ),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (_gameWorld.paused) {
                      _gameWorld.resumeEngine();
                    } else {
                      _gameWorld.pauseEngine();
                    }
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _gameWorld.paused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
