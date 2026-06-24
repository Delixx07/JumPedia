import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/utils/logger.dart';

/// ═══════════════════════════════════════
/// AUTH SERVICE — JumPedia
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

      // Step 5: Pastikan dokumen user ada di Firestore
      // Kita panggil _ensureUserDocument agar jika dokumen terhapus tetap dibuat kembali
      await _ensureUserDocument(userCredential.user!);

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
  /// LINK GUEST TO GOOGLE
  /// ═══════════════════════════════════════
  /// Menghubungkan akun anonymous (guest) yang sedang login dengan akun
  /// Google. Jika berhasil, username di dokumen Firestore users/{uid}
  /// diupdate menjadi displayName dari akun Google.
  Future<UserCredential?> linkGuestToGoogle() async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.warning('No current user to link');
      return null;
    }

    if (!user.isAnonymous) {
      AppLogger.warning('Current user is not anonymous; abort linking');
      return null;
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        AppLogger.debug('Google Sign-In cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link anonymous account with Google credential
      final UserCredential linked =
          await user.linkWithCredential(credential);

      // Jika UID tetap sama, update username di Firestore
      final linkedUid = linked.user?.uid;
      if (linkedUid != null && linkedUid == user.uid) {
        final displayName =
            linked.user?.displayName ?? googleUser.displayName ?? 'Player';
        final docRef =
            _firestore.collection(FirestorePaths.usersCollection).doc(linkedUid);
        try {
          await docRef.update({FirestorePaths.fieldUsername: displayName});
        } catch (e) {
          // Jika dokumen belum ada, set dengan merge
          await docRef.set({FirestorePaths.fieldUsername: displayName}, SetOptions(merge: true));
        }
      } else {
        AppLogger.warning(
            'Linked UID differs from anonymous UID: $linkedUid vs ${user.uid}');
      }

      AppLogger.info('Guest linked to Google: ${linked.user?.displayName}');
      return linked;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Linking error', error: e);
      // Bubble up to UI for handling (e.g., credential-already-in-use)
      rethrow;
    } catch (e, st) {
      AppLogger.error('Unexpected linking error', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// ═══════════════════════════════════════
  /// ENSURE USER DOCUMENT
  /// ═══════════════════════════════════════
  /// Memastikan dokumen user ada di Firestore. Jika belum ada, buat baru.
  Future<void> _ensureUserDocument(User user) async {
    final docRef =
        _firestore.collection(FirestorePaths.usersCollection).doc(user.uid);
    
    final doc = await docRef.get();
    
    if (!doc.exists) {
      // Ambil username dari email (bagian sebelum @) sebagai default
      String defaultUsername = 'Player';
      if (user.email != null && user.email!.contains('@')) {
        defaultUsername = user.email!.split('@')[0];
      } else if (user.displayName != null) {
        defaultUsername = user.displayName!;
      }

      final userData = {
        FirestorePaths.fieldUid: user.uid,
        FirestorePaths.fieldUsername: defaultUsername,
        FirestorePaths.fieldAvatarPath: 'panda.png', // Default avatar
        FirestorePaths.fieldNotificationsEnabled: true, // Default enabled
        FirestorePaths.fieldTotalGamesPlayed: 0,
        FirestorePaths.fieldCreatedAt: FieldValue.serverTimestamp(),
      };

      await docRef.set(userData);
      AppLogger.firestore('CREATE', FirestorePaths.userDoc(user.uid),
          detail: 'User document restored/created for ${user.email}');
    }
  }

  /// ═══════════════════════════════════════
  /// SIGN IN AS GUEST (anonymous)
  /// ═══════════════════════════════════════
  /// Login tanpa akun — progress tersimpan di Firestore selama device
  /// & instalasi yang sama. Cocok untuk user yang mau coba game dulu
  /// sebelum sign-in beneran.
  Future<UserCredential?> signInAsGuest() async {
    try {
      final userCredential = await _auth.signInAnonymously();

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _createGuestUserDocument(userCredential.user!);
      }

      AppLogger.info('Guest login berhasil: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Guest auth error', error: e);
      rethrow;
    } catch (e, st) {
      AppLogger.error('Guest sign-in error', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// // CRUD: CREATE — Dokumen user untuk guest, label "Tamu".
  Future<void> _createGuestUserDocument(User user) async {
    final docRef =
        _firestore.collection(FirestorePaths.usersCollection).doc(user.uid);

    final userData = {
      FirestorePaths.fieldUid: user.uid,
      FirestorePaths.fieldUsername: 'Tamu',
      FirestorePaths.fieldAvatarPath: 'panda.png', // Default avatar
      FirestorePaths.fieldNotificationsEnabled: true, // Default enabled
      FirestorePaths.fieldTotalGamesPlayed: 0,
      FirestorePaths.fieldCreatedAt: FieldValue.serverTimestamp(),
    };

    await docRef.set(userData);
    AppLogger.firestore('CREATE', FirestorePaths.userDoc(user.uid),
        detail: 'Guest user document created');
  }

  /// ═══════════════════════════════════════
  /// SIGN OUT
  /// ═══════════════════════════════════════
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      
      // Jika user adalah Guest (Anonymous), hapus dokumen Firestore-nya DAN akun Auth-nya
      // agar tidak terjadi "flooding" baik di Database maupun di daftar Auth Firebase.
      if (user != null && user.isAnonymous) {
        final uid = user.uid;
        
        // 1. Hapus dokumen di Firestore (User & Leaderboard)
        await _firestore
            .collection(FirestorePaths.usersCollection)
            .doc(uid)
            .delete();
            
        await _firestore
            .collection(FirestorePaths.leaderboardCollection)
            .doc(uid)
            .delete();
            
        // 2. Hapus akun dari Firebase Authentication (Clean up daftar di Console)
        // Note: user.delete() otomatis melakukan sign out.
        await user.delete();
        
        AppLogger.info('Guest account and data cleaned up permanently from Firebase');
      } else {
        // Sign out normal untuk user Google (Data tetap tersimpan aman)
        await Future.wait([
          _auth.signOut(),
          _googleSignIn.signOut(),
        ]);
        AppLogger.info('Google user signed out');
      }
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
