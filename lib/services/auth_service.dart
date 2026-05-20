import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/utils/logger.dart';

/// ═══════════════════════════════════════
/// AUTH SERVICE — SDG Eco-Jump
/// ═══════════════════════════════════════
/// Mengelola autentikasi pengguna menggunakan Firebase Auth + Google Sign-In.
/// Juga bertanggung jawab membuat dokumen user baru di Firestore saat login pertama.

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream status autentikasi untuk digunakan oleh AuthProvider.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// User yang sedang login saat ini.
  User? get currentUser => _auth.currentUser;

  /// ═══════════════════════════════════════
  /// SIGN IN WITH GOOGLE
  /// ═══════════════════════════════════════
  /// Melakukan autentikasi via Google Sign-In, lalu login ke Firebase.
  /// Jika user baru (pertama kali login), buat dokumen di koleksi 'users'.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Step 1: Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User membatalkan login
        AppLogger.debug('Google Sign-In dibatalkan oleh user');
        return null;
      }

      // Step 2: Ambil authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Step 3: Buat credential untuk Firebase Auth
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Sign in ke Firebase dengan credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Step 5: Cek apakah user baru (pertama kali login)
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _createUserDocument(userCredential.user!);
      }

      AppLogger.info('Login berhasil: ${userCredential.user?.displayName}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth error', error: e);
      rethrow;
    } catch (e, st) {
      AppLogger.error('Sign-in error', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// ═══════════════════════════════════════
  /// CREATE USER DOCUMENT
  /// ═══════════════════════════════════════
  /// // CRUD: CREATE — Buat dokumen baru di koleksi 'users' saat login pertama.
  Future<void> _createUserDocument(User user) async {
    final docRef =
        _firestore.collection(FirestorePaths.usersCollection).doc(user.uid);

    final userData = {
      FirestorePaths.fieldUid: user.uid,
      FirestorePaths.fieldUsername: user.displayName ?? 'Player',
      FirestorePaths.fieldTotalGamesPlayed: 0,
      FirestorePaths.fieldCreatedAt: FieldValue.serverTimestamp(),
    };

    // CRUD: CREATE
    await docRef.set(userData);
    AppLogger.firestore('CREATE', FirestorePaths.userDoc(user.uid),
        detail: 'User document created');
  }

  /// ═══════════════════════════════════════
  /// SIGN OUT
  /// ═══════════════════════════════════════
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      AppLogger.info('User signed out');
    } catch (e, st) {
      AppLogger.error('Sign-out error', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// ═══════════════════════════════════════
  /// DELETE ACCOUNT
  /// ═══════════════════════════════════════
  /// Menghapus akun dari Firebase Auth DAN dokumen user dari Firestore.
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.warning('Tidak ada user yang login untuk dihapus');
        return;
      }

      final uid = user.uid;

      // CRUD: DELETE — Hapus dokumen user dari Firestore
      await _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(uid)
          .delete();
      AppLogger.firestore('DELETE', FirestorePaths.userDoc(uid),
          detail: 'User document deleted');

      // Hapus akun dari Firebase Auth
      await user.delete();
      AppLogger.info('Akun $uid berhasil dihapus');

      // Sign out dari Google
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e) {
      // Jika butuh re-authentication
      if (e.code == 'requires-recent-login') {
        AppLogger.warning('Perlu re-login sebelum hapus akun');
        rethrow;
      }
      AppLogger.error('Delete account error', error: e);
      rethrow;
    } catch (e, st) {
      AppLogger.error('Delete account error', error: e, stackTrace: st);
      rethrow;
    }
  }
}
