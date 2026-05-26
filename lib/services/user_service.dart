import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/utils/logger.dart';
import '../models/user_model.dart';

/// ═══════════════════════════════════════
/// USER SERVICE — JumPedia
/// ═══════════════════════════════════════
/// Mengelola operasi CRUD ke koleksi 'users' di Firestore.
/// Catatan: createUser() dipanggil oleh AuthService saat login pertama.

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ═══════════════════════════════════════
  /// GET USER
  /// ═══════════════════════════════════════
  /// // CRUD: READ — Baca dokumen user berdasarkan UID.
  Future<UserModel?> getUser(String uid) async {
    // CRUD: READ
    final doc = await _firestore
        .collection(FirestorePaths.usersCollection)
        .doc(uid)
        .get();

    AppLogger.firestore('READ', FirestorePaths.userDoc(uid));

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// ═══════════════════════════════════════
  /// UPDATE USERNAME
  /// ═══════════════════════════════════════
  /// // CRUD: UPDATE — Update field username di dokumen user.
  Future<void> updateUsername(String uid, String newUsername) async {
    // CRUD: UPDATE
    await _firestore
        .collection(FirestorePaths.usersCollection)
        .doc(uid)
        .update({
      FirestorePaths.fieldUsername: newUsername,
    });

    AppLogger.firestore('UPDATE', FirestorePaths.userDoc(uid),
        detail: 'Username updated to $newUsername');
  }

  /// ═══════════════════════════════════════
  /// DELETE USER DOCUMENT
  /// ═══════════════════════════════════════
  /// // CRUD: DELETE — Hapus dokumen user dari Firestore.
  /// Biasanya dipanggil dari AuthService.deleteAccount().
  Future<void> deleteUser(String uid) async {
    // CRUD: DELETE
    await _firestore
        .collection(FirestorePaths.usersCollection)
        .doc(uid)
        .delete();

    AppLogger.firestore('DELETE', FirestorePaths.userDoc(uid),
        detail: 'User document deleted');
  }

  /// ═══════════════════════════════════════
  /// GET ALL USERS (ADMIN/DEBUG)
  /// ═══════════════════════════════════════
  /// // CRUD: READ — Baca semua dokumen dari koleksi 'users'.
  /// Hanya digunakan untuk keperluan debug/admin.
  Future<List<UserModel>> getAllUsers() async {
    // CRUD: READ
    final querySnapshot =
        await _firestore.collection(FirestorePaths.usersCollection).get();

    AppLogger.firestore('READ', FirestorePaths.usersCollection,
        detail: 'Fetched ${querySnapshot.docs.length} users');

    return querySnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  /// ═══════════════════════════════════════
  /// STREAM USER (REAL-TIME)
  /// ═══════════════════════════════════════
  /// // CRUD: READ (stream) — Stream perubahan real-time pada dokumen user.
  Stream<UserModel?> streamUser(String uid) {
    return _firestore
        .collection(FirestorePaths.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }
}
