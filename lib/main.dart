import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/utils/logger.dart';
import 'firebase_options.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/game_screen.dart';
import 'presentation/screens/game_over_screen.dart';
import 'presentation/screens/leaderboard_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'services/notification_service.dart';

/// ═══════════════════════════════════════
/// APP CONFIG — Flutter Flavors
/// ═══════════════════════════════════════
class AppConfig {
  static bool isDev = true;
  static bool allowScoreReset = true;
  static String appLabel = 'SDG Eco-Jump';
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
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/game', builder: (_, __) => const GameScreen()),
    GoRoute(path: '/game-over', builder: (_, __) => const GameOverScreen()),
    GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);

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

  // Setup notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Firebase Analytics hanya di production
  if (!AppConfig.isDev) {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    AppLogger.info('Firebase Analytics enabled (prod)');
  }

  AppLogger.info('App started: ${AppConfig.appLabel} (isDev: ${AppConfig.isDev})');

  runApp(const ProviderScope(child: SdgEcoJumpApp()));
}

void main() => mainCommon();

/// ═══════════════════════════════════════
/// ROOT APP WIDGET
/// ═══════════════════════════════════════
class SdgEcoJumpApp extends StatelessWidget {
  const SdgEcoJumpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appLabel,
      debugShowCheckedModeBanner: AppConfig.isDev,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
      ),
    );
  }
}
