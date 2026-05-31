import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
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
/// Menyediakan kontrol on-screen (mobile) dan keyboard (desktop).
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late GameWorld _gameWorld;
  final FocusNode _focusNode = FocusNode();

  /// Apakah game over sudah terpicu. Saat true, overlay Game Over inline
  /// ditampilkan sebagai safety net (kalau navigasi ke /game-over delayed
  /// atau gagal, user tetap punya tombol Restart / Back Home).
  bool _isGameOver = false;

  /// Apakah platform ini punya keyboard fisik dan tidak butuh on-screen
  /// control (desktop / web). Mobile + tablet selalu dapat tombol.
  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    _initializeGame();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(scoreProvider.notifier).resetScore();
      ref.read(hpProvider.notifier).resetHp();
      ref.read(shownFactsProvider.notifier).reset();
      ref.read(factCheckpointProvider.notifier).reset();
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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

  /// Dipanggil oleh GameWorld saat HP = 0.
  /// Penting: jangan blocking — pause engine dulu, tampilkan overlay game
  /// over inline sebagai safety net, lalu coba navigate ke /game-over.
  /// Sebelumnya bug: kalau Firestore lambat, `await save → context.go`
  /// menyebabkan layar stuck tanpa opsi apa pun.
  void _handleGameOver() {
    if (_isGameOver) return;
    AppLogger.game('GameScreen received onGameOver');

    // Hentikan game loop & input langsung supaya tidak ada update lagi.
    if (!_gameWorld.paused) {
      _gameWorld.pauseEngine();
    }

    if (mounted) {
      setState(() => _isGameOver = true);
    }

    final score = ref.read(scoreProvider);
    final uid = ref.read(currentUserUidProvider);

    // Fire-and-forget save score — JANGAN await sebelum navigate.
    if (uid != null) {
      final scoreService = ScoreService();
      scoreService
          .saveScore(uid, score)
          .then((_) => scoreService.incrementGamesPlayed(uid))
          .catchError((Object e) {
        AppLogger.error('Failed to save score', error: e);
      });
    }

    // Navigate via post-frame callback — aman dari "navigate during build".
    // Kalau navigasi entah kenapa gagal, overlay inline tetap muncul jadi
    // user tidak pernah stuck tanpa tombol.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/game-over');
      }
    });
  }

  /// Keyboard handler untuk desktop / web — A/D, panah kiri/kanan.
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final isLeft = event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA;
    final isRight = event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD;

    if (!isLeft && !isRight) return KeyEventResult.ignored;

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (isLeft) _gameWorld.playerMoveLeft();
      if (isRight) _gameWorld.playerMoveRight();
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) {
      _gameWorld.playerStop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Stack(
          children: [
            GameWidget(
              game: _gameWorld,
              overlayBuilderMap: {
                'hud': (context, game) => const HudOverlay(),
                'funFact': (context, game) =>
                    FunFactOverlay(game: game as GameWorld),
              },
              initialActiveOverlays: const ['hud'],
            ),

            // ─── Pause button (kanan atas) ──────────
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
                        _gameWorld.paused
                            ? Icons.play_arrow
                            : Icons.pause,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── Inline Game Over overlay (safety net) ──
            // Muncul saat HP=0; tetap di sini sampai navigasi ke
            // /game-over benar-benar terjadi. Memberi user tombol manual
            // Restart / Back Home jadi tidak pernah stuck.
            if (_isGameOver) _GameOverOverlay(
              onRestart: () => context.go('/game'),
              onHome: () => context.go('/home'),
            ),

            // ─── On-screen controls (mobile) ────────
            if (!_isDesktop && !_isGameOver)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DirectionButton(
                            icon: Icons.arrow_back_rounded,
                            label: 'Left',
                            onPressStart: _gameWorld.playerMoveLeft,
                            onPressEnd: _gameWorld.playerStop,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _DirectionButton(
                            icon: Icons.arrow_forward_rounded,
                            label: 'Right',
                            onPressStart: _gameWorld.playerMoveRight,
                            onPressEnd: _gameWorld.playerStop,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ─── Keyboard hint (desktop) ────────────
            if (_isDesktop)
              Positioned(
                left: 12,
                bottom: 12,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.keyboard_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'A / D  or  ← →',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tombol arah on-screen — hold to move, lepas untuk berhenti.
class _DirectionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  const _DirectionButton({
    required this.icon,
    required this.label,
    required this.onPressStart,
    required this.onPressEnd,
  });

  @override
  State<_DirectionButton> createState() => _DirectionButtonState();
}

class _DirectionButtonState extends State<_DirectionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
    if (value) {
      widget.onPressStart();
    } else {
      widget.onPressEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _pressed
                ? const [AppColors.primary, AppColors.accent]
                : [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.35),
                  ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _pressed
                ? AppColors.accent.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.18),
            width: 1.5,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay Game Over inline — safety net agar user selalu bisa
/// Restart atau kembali ke Home walaupun navigasi ke /game-over delayed.
class _GameOverOverlay extends StatelessWidget {
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const _GameOverOverlay({
    required this.onRestart,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgMid,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sentiment_very_dissatisfied_rounded,
                color: AppColors.danger,
                size: 56,
              ),
              const SizedBox(height: 8),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your character is gone 💀',
                style: TextStyle(
                  color: AppColors.textLo,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRestart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Restart',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onHome,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textHi,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
