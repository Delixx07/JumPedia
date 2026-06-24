import 'dart:async';

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
import '../../game/overlays/tutorial_overlay.dart';
import '../../game/world/game_world.dart';
import '../../providers/hp_provider.dart';
import '../../providers/score_provider.dart';
import '../../providers/fun_fact_provider.dart';
import '../../services/score_service.dart';
import '../../services/user_service.dart';
import '../../services/collected_fact_service.dart';
import '../../services/achievement_service.dart';
import '../../models/achievement_model.dart';
import '../../providers/auth_provider.dart';

import '../../services/audio_service.dart';

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

  /// Apakah menu jeda (pause) sedang terbuka.
  bool _isPauseMenuOpen = false;

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
      // Tampilkan tutorial sekali di awal & pause game. Resume + remove saat
      // pemain menekan "Start!". (Ditambah manual, BUKAN lewat
      // initialActiveOverlays, agar rebuild GameWidget tidak memunculkannya
      // kembali setelah ditutup.)
      _gameWorld.overlays.add('tutorial');
      _gameWorld.pauseEngine();
      _focusNode.requestFocus();
      if (mounted) setState(() {});
    });
  }

  /// Tutup tutorial & mulai game.
  /// Pola sama dengan versi yang sudah terbukti bekerja: lepas overlay lalu
  /// resume engine. `setState` memastikan kontrol in-game ikut muncul.
  void _dismissTutorial() {
    _gameWorld.overlays.remove('tutorial');
    if (_gameWorld.paused) {
      _gameWorld.resumeEngine();
      _focusNode.requestFocus();
    }
    if (mounted) setState(() {});
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
        if (mounted) setState(() {});
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
    final isGuest = ref.read(isGuestProvider);

    // Fire-and-forget save score — JANGAN await sebelum navigate.
    // Skor TAMU dicatat di history pribadi tapi tidak masuk leaderboard global.
    if (uid != null) {
      final scoreService = ScoreService();
      scoreService
          .saveScore(uid, score, addToLeaderboard: !isGuest)
          .then((_) => scoreService.incrementGamesPlayed(uid))
          .then((_) => _evaluateAchievements(uid))
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

  /// Hitung statistik terbaru lalu buka lencana yang syaratnya terpenuhi.
  /// Dipanggil setelah skor & total game tersimpan (fire-and-forget).
  Future<void> _evaluateAchievements(String uid) async {
    final bestScore = await ScoreService().getUserBestScore(uid);
    final facts = await CollectedFactService().getCollectedContents(uid);
    final user = await UserService().getUser(uid);

    final stats = AchievementStats(
      bestScore: bestScore,
      totalGames: user?.totalGamesPlayed ?? 0,
      factsCollected: facts.length,
    );
    await AchievementService().evaluateAndUnlock(uid, stats);
  }

  /// Buka menu jeda: pause engine & tampilkan menu (Resume / Restart / Home).
  void _openPauseMenu() {
    if (!_gameWorld.paused) _gameWorld.pauseEngine();
    setState(() => _isPauseMenuOpen = true);
  }

  /// Tutup menu jeda & lanjutkan permainan.
  void _closePauseMenu() {
    if (_gameWorld.paused) _gameWorld.resumeEngine();
    _focusNode.requestFocus();
    setState(() => _isPauseMenuOpen = false);
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

  /// Apakah ada overlay yang memblokir gameplay (tutorial / fun fact).
  /// Saat aktif, tombol kontrol in-game (home/pause/arah) disembunyikan
  /// agar tidak bentrok dengan pause dari overlay.
  bool get _overlayActive =>
      _gameWorld.overlays.isActive('tutorial') ||
      _gameWorld.overlays.isActive('funFact');

  @override
  Widget build(BuildContext context) {
    final controlsVisible = !_isGameOver && !_overlayActive && !_isPauseMenuOpen;
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
                'tutorial': (context, game) =>
                    TutorialOverlay(onStart: _dismissTutorial),
                'countdown': (context, game) =>
                    _CountdownOverlay(game: game as GameWorld),
              },
              // Hanya 'hud' di initial. 'tutorial' ditambahkan manual di
              // initState — kalau dimasukkan ke initialActiveOverlays, rebuild
              // GameWidget (akibat setState) bisa memunculkannya KEMBALI setelah
              // ditutup (bug "tutorial tidak hilang saat Start").
              initialActiveOverlays: const ['hud'],
            ),

            // ─── Tombol Pause (satu, kanan atas) ────
            // Membuka menu jeda (Resume / Restart / Home). Menggantikan dua
            // tombol terpisah yang dulu berdesakan dengan HUD.
            if (controlsVisible)
              Positioned(
                top: 10,
                right: 12,
                child: SafeArea(
                  child: _RoundIconButton(
                    icon: Icons.pause_rounded,
                    onTap: _openPauseMenu,
                  ),
                ),
              ),

            // ─── Menu Jeda (overlay) ────────────────
            if (_isPauseMenuOpen)
              _PauseMenu(
                onResume: _closePauseMenu,
                onRestart: () => context.go('/game'),
                onHome: () => context.go('/home'),
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
            if (!_isDesktop && controlsVisible)
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

/// Menu jeda in-game — Resume / Restart / Home. Tampil di atas game yang
/// sudah di-pause, dengan latar gelap blur agar fokus.
class _PauseMenu extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const _PauseMenu({
    required this.onResume,
    required this.onRestart,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.bgMid,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pause_rounded,
                    color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 12),
              const Text(
                'Jeda',
                style: TextStyle(
                  color: AppColors.textHi,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 22),
              _PauseMenuButton(
                icon: Icons.play_arrow_rounded,
                label: 'Lanjut Main',
                filled: true,
                onTap: onResume,
              ),
              const SizedBox(height: 10),
              _PauseMenuButton(
                icon: Icons.refresh_rounded,
                label: 'Ulang',
                filled: false,
                onTap: onRestart,
              ),
              const SizedBox(height: 10),
              _PauseMenuButton(
                icon: Icons.home_rounded,
                label: 'Beranda',
                filled: false,
                onTap: onHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _PauseMenuButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(icon),
              label: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textHi,
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.7)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(icon),
              label: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
    );
  }
}

/// Tombol bulat kecil semi-transparan untuk kontrol in-game (home/pause).
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
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

/// Overlay Countdown 3-2-1 sebelum game dilanjutkan.
/// Muncul setelah Fun Fact ditutup agar player tidak kaget.
class _CountdownOverlay extends StatefulWidget {
  final GameWorld game;
  const _CountdownOverlay({required this.game});

  @override
  State<_CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<_CountdownOverlay> {
  int _count = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AudioService.playTick(); // Play sound on 3
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_count > 1) {
        setState(() => _count--);
        AudioService.playTick(); // Play sound on 2 and 1
      } else {
        _timer?.cancel();
        widget.game.resumeAfterCountdown();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Text(
          '$_count',
          style: const TextStyle(
            color: AppColors.warn,
            fontSize: 120,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            shadows: [
              Shadow(
                blurRadius: 20,
                color: Colors.black54,
                offset: Offset(4, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
