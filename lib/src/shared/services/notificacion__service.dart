import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermission();
    await _setupLocalNotifications();
    await _saveToken();
    _listenForeground();
    _listenTokenRefresh();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission();
  }

  Future<void> _saveToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;

    print("TOKEN: $token");

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client
        .from('perfiles')
        .update({'fcm_token': token})
        .eq('id', userId);
  }

  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('perfiles')
          .update({'fcm_token': newToken})
          .eq('id', userId);
    });
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      'allfood_channel',
      'AllFood Notificaciones',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation
            <AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'allfood_channel',
            'AllFood Notificaciones',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  Future<void> resetSessionIdentifier() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('perfiles')
            .update({'fcm_token': null})
            .eq('id', userId);
      }
    } catch (_) {}

    try {
      await _messaging.deleteToken();
    } catch (_) {}
  }
}
