import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../firebase_options.dart';
import 'settings_service.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _defaultAndroidChannel =
    AndroidNotificationChannel(
      'finance_tracker_high_importance',
      'Finance Tracker Alerts',
      description: 'General notifications for Finance Tracker',
      importance: Importance.max,
    );

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService()._showRemoteMessage(message);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SettingsService _settingsService = SettingsService();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);

    // Local notifications initialization
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Create Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_defaultAndroidChannel);

    // Request notification permission
    await _ensurePermissions();

    // Foreground presentation (iOS/macOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((message) async {
      await _showRemoteMessage(message);
    });

    // App opened from background via notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // Optionally handle deep-links or navigation
    });

    _initialized = true;
  }

  Future<void> _ensurePermissions() async {
    final notificationsEnabled = await _settingsService.getNotifications();
    if (!notificationsEnabled) return;

    // iOS/Android 13+ request
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsService.setNotifications(enabled);
    if (enabled) {
      await _ensurePermissions();
    } else {
      await _localNotifications.cancelAll();
    }
  }

  Future<void> showLocalNotification(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    final notificationsEnabled = await _settingsService.getNotifications();
    if (!notificationsEnabled) return;

    final androidDetails = AndroidNotificationDetails(
      _defaultAndroidChannel.id,
      _defaultAndroidChannel.name,
      channelDescription: _defaultAndroidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'local_notification',
    );
  }

  void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    // Handle notification tap
    // For example, navigate to a specific screen based on payload
    // final String? payload = notificationResponse.payload;
    // if (payload != null) {
    //   debugPrint('notification payload: $payload');
    // }
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> _showRemoteMessage(RemoteMessage message) async {
    final notificationsEnabled = await _settingsService.getNotifications();
    if (!notificationsEnabled) return;

    final notification = message.notification;
    final android = notification?.android;

    final androidDetails = AndroidNotificationDetails(
      _defaultAndroidChannel.id,
      _defaultAndroidChannel.name,
      channelDescription: _defaultAndroidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: android?.smallIcon,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification?.title ?? 'Finance Tracker',
      notification?.body ?? '',
      details,
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }
}
