import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants/firestore_paths.dart';
import '../core/utils/logger.dart';

/// ═══════════════════════════════════════
/// NOTIFICATION SERVICE — JumPedia
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
    'JumPedia Notifications',
    description: 'Notifications for the JumPedia game',
    importance: Importance.high,
  );

  /// ID tetap untuk notifikasi pengingat harian. Dipakai saat menjadwalkan
  /// maupun membatalkan, supaya tidak terjadi penjadwalan ganda.
  static const int _dailyReminderId = 1001;

  /// ═══════════════════════════════════════
  /// INITIALIZE
  /// ═══════════════════════════════════════
  /// Panggil method ini di main() setelah Firebase.initializeApp().
  Future<void> initialize() async {
    // Inisialisasi database zona waktu — wajib sebelum zonedSchedule dipakai
    // untuk menjadwalkan notifikasi harian.
    tz.initializeTimeZones();

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
        notification.title ?? 'JumPedia',
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

  /// ═══════════════════════════════════════
  /// SCHEDULE DAILY REMINDER (lokal)
  /// ═══════════════════════════════════════
  /// Menjadwalkan notifikasi pengingat yang muncul SETIAP HARI pada jam
  /// [hour]:[minute] (waktu lokal device). Tidak butuh server — murni lokal.
  /// Aman dipanggil berulang: penjadwalan lama dengan ID sama akan ditimpa.
  Future<void> scheduleDailyReminder({
    required String title,
    required String body,
    int hour = 10,
    int minute = 20,
  }) async {
    // Hitung waktu tayang berikutnya pada jam:menit yang diminta. Jika jam
    // tersebut hari ini sudah lewat, geser ke hari berikutnya.
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      _dailyReminderId,
      title,
      body,
      scheduled,
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
      // inexact: tidak butuh izin SCHEDULE_EXACT_ALARM (Android 12+), jadi
      // notifikasi tetap muncul tanpa minta izin alarm khusus.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Interpretasi waktu untuk iOS (wajib diisi oleh plugin).
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Ulang tiap hari pada jam:menit yang sama.
      matchDateTimeComponents: DateTimeComponents.time,
    );

    AppLogger.info('Pengingat harian dijadwalkan pukul '
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
  }

  /// Batalkan pengingat harian (mis. saat user mematikan toggle notifikasi).
  Future<void> cancelDailyReminder() async {
    await _localNotifications.cancel(_dailyReminderId);
    AppLogger.info('Pengingat harian dibatalkan');
  }

  /// ═══════════════════════════════════════
  /// TEST NOTIFICATION
  /// ═══════════════════════════════════════
  /// Munculkan notifikasi SAAT ITU JUGA — untuk menguji/demo bahwa
  /// notifikasi bekerja tanpa menunggu jadwal harian.
  Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {
    await _localNotifications.show(
      9999,
      title,
      body,
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
    );
    AppLogger.info('Notifikasi uji ditampilkan');
  }
}
