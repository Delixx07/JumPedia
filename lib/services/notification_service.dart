import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/utils/logger.dart';

/// ═══════════════════════════════════════
/// NOTIFICATION SERVICE — SDG Eco-Jump
/// ═══════════════════════════════════════
/// Setup Firebase Cloud Messaging + Local Notifications.
/// Menangani notifikasi foreground, background, dan penyimpanan FCM token.
///
/// Catatan untuk tim:
/// Kirim notifikasi harian dari Firebase Console atau Cloud Functions:
/// "Ayo main lagi! Masih ada fakta SDG 4 yang belum kamu temukan hari ini!"

/// Handler untuk background messages — harus top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.debug('Background message received: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Channel untuk Android local notifications.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sdg_ecojump_channel',
    'SDG Eco-Jump Notifications',
    description: 'Notifikasi untuk SDG Eco-Jump game',
    importance: Importance.high,
  );

  /// ═══════════════════════════════════════
  /// INITIALIZE
  /// ═══════════════════════════════════════
  /// Panggil method ini di main() setelah Firebase.initializeApp().
  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Minta izin notifikasi (iOS & Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    AppLogger.info(
        'FCM permission status: ${settings.authorizationStatus.name}');

    // Setup local notifications untuk foreground
    await _setupLocalNotifications();

    // Listen untuk foreground messages
    _setupForegroundListener();

    // Listen untuk tap pada notifikasi (app di background)
    _setupBackgroundTapListener();

    AppLogger.info('NotificationService initialized');
  }

  /// ═══════════════════════════════════════
  /// SETUP LOCAL NOTIFICATIONS
  /// ═══════════════════════════════════════
  Future<void> _setupLocalNotifications() async {
    // Android initialization
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle tap pada local notification
        AppLogger.debug('Local notification tapped: ${response.payload}');
      },
    );

    // Buat notification channel untuk Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// ═══════════════════════════════════════
  /// FOREGROUND LISTENER
  /// ═══════════════════════════════════════
  /// Tampilkan local notification saat app di foreground.
  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.debug('Foreground message: ${message.notification?.title}');

      final notification = message.notification;
      if (notification == null) return;

      // Tampilkan sebagai local notification
      _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'SDG Eco-Jump',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['route'], // Optional: untuk navigasi
      );
    });
  }

  /// ═══════════════════════════════════════
  /// BACKGROUND TAP LISTENER
  /// ═══════════════════════════════════════
  /// Handle saat user tap notifikasi yang masuk ketika app di background.
  void _setupBackgroundTapListener() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.debug(
          'Notification opened app: ${message.notification?.title}');
      // Bisa navigasi ke screen tertentu berdasarkan message.data
      // Contoh: navigasi ke leaderboard jika data['route'] == 'leaderboard'
    });
  }

  /// ═══════════════════════════════════════
  /// SAVE FCM TOKEN
  /// ═══════════════════════════════════════
  /// Ambil FCM token dan simpan ke Firestore users/{uid}/fcm_token.
  /// // CRUD: UPDATE — Simpan FCM token ke dokumen user.
  Future<void> saveFcmToken(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) {
        AppLogger.warning('FCM token null');
        return;
      }

      // CRUD: UPDATE
      await _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(userId)
          .update({
        FirestorePaths.fcmTokenField: token,
      });

      AppLogger.firestore('UPDATE', FirestorePaths.userDoc(userId),
          detail: 'FCM token saved');

      // Listen untuk token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        // CRUD: UPDATE
        await _firestore
            .collection(FirestorePaths.usersCollection)
            .doc(userId)
            .update({
          FirestorePaths.fcmTokenField: newToken,
        });
        AppLogger.firestore('UPDATE', FirestorePaths.userDoc(userId),
            detail: 'FCM token refreshed');
      });
    } catch (e, st) {
      AppLogger.error('Error saving FCM token', error: e, stackTrace: st);
    }
  }
}
