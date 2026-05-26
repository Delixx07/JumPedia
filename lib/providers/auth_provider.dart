import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

/// ═══════════════════════════════════════
/// AUTH PROVIDER — JumPedia
/// ═══════════════════════════════════════
/// Riverpod providers untuk status autentikasi user.
/// Meng-expose AuthService dan stream auth state ke seluruh app.

/// Provider untuk instance AuthService (singleton).
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// StreamProvider untuk auth state changes.
/// Widget bisa watch provider ini untuk react ke login/logout.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider untuk mendapatkan current user UID.
/// Mengembalikan null jika belum login.
final currentUserUidProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => user?.uid).value;
});

/// Provider untuk status login (bool).
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => user != null).value ?? false;
});
