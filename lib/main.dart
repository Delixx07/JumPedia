import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/api_keys.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'firebase_options.dart';
import 'providers/language_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/game_screen.dart';
import 'presentation/screens/game_over_screen.dart';
import 'presentation/screens/leaderboard_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/about_screen.dart';
import 'presentation/screens/fun_facts_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/score_history_screen.dart';
import 'presentation/screens/main_shell.dart';
import 'services/audio_service.dart';
import 'services/haptic_service.dart';
import 'services/notification_service.dart';

/// ═══════════════════════════════════════
/// APP CONFIG — Flutter Flavors
/// ═══════════════════════════════════════
class AppConfig {
  static bool isDev = true;
  static bool allowScoreReset = true;
  static String appLabel = 'JumPedia';
  static String firebaseProject = 'sdg-ecojump-dev';
}

/// ═══════════════════════════════════════
/// ROUTER — Go Router Setup
/// ═══════════════════════════════════════
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

    // Routes di luar shell — fullscreen / modal.
    GoRoute(path: '/game', builder: (_, __) => const GameScreen()),
    GoRoute(
        path: '/game-over',
        pageBuilder: (_, s) => _fadePage(s, const GameOverScreen())),
    GoRoute(
        path: '/settings',
        pageBuilder: (_, s) => _fadePage(s, const SettingsScreen())),
    GoRoute(
        path: '/about',
        pageBuilder: (_, s) => _fadePage(s, const AboutScreen())),
    GoRoute(
        path: '/profile',
        pageBuilder: (_, s) => _fadePage(s, const ProfileScreen())),
    GoRoute(path: '/score-history', builder: (_, __) => const ScoreHistoryScreen()),

    // Shell dengan NavigationBar — Home / Fun Facts / Leaderboard.
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/fun-facts',
          builder: (_, __) => const FunFactsScreen(),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (_, __) => const LeaderboardScreen(),
        ),
      ],
    ),
  ],
);

/// Transisi halaman fade + slide-up halus untuk route non-shell,
/// memberi kesan navigasi yang lebih premium.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 260),
    child: child,
    transitionsBuilder: (context, animation, _, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// ═══════════════════════════════════════
/// MAIN ENTRY POINT
/// ═══════════════════════════════════════
Future<void> mainCommon() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Setup logger
  AppLogger.init(enabled: AppConfig.isDev);

  // Inisialisasi Supabase (untuk Storage foto profil). Hanya jika kredensial
  // sudah diisi di api_keys.dart — agar app tetap jalan tanpa Supabase.
  if (ApiKeys.hasSupabase) {
    try {
      await Supabase.initialize(
        url: ApiKeys.supabaseUrl,
        anonKey: ApiKeys.supabaseAnonKey,
      );
      AppLogger.info('Supabase initialized');
    } catch (e) {
      AppLogger.warning('Supabase init gagal: $e', tag: 'Supabase');
    }
  }

  // Setup notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Firebase Analytics hanya di production
  if (!AppConfig.isDev) {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    AppLogger.info('Firebase Analytics enabled (prod)');
  }

  // Muat preferensi lokal (mis. pilihan bahasa fun fact) sebelum runApp.
  final prefs = await SharedPreferences.getInstance();

  // Terapkan volume tersimpan & mulai musik latar (diam jika bgm.mp3 belum ada).
  AudioService.setBgmVolume(prefs.getDouble('audio_bgm_volume') ?? 0.5);
  AudioService.setSfxVolume(prefs.getDouble('audio_sfx_volume') ?? 0.8);
  AudioService.setMuted(prefs.getBool('audio_muted') ?? false);
  HapticService.setEnabled(prefs.getBool('haptic_enabled') ?? true);


  AppLogger.info('App started: ${AppConfig.appLabel} (isDev: ${AppConfig.isDev})');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const JumPediaApp(),
    ),
  );
}

void main() => mainCommon();

/// ═══════════════════════════════════════
/// ROOT APP WIDGET — JumPedia
/// ═══════════════════════════════════════
class JumPediaApp extends StatelessWidget {
  const JumPediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appLabel,
      debugShowCheckedModeBanner: AppConfig.isDev,
      routerConfig: _router,
      theme: AppTheme.light,
    );
  }
}
