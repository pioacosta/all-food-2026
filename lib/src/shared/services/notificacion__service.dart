import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ⚠️ Debe ser top-level (fuera de cualquier clase)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('BG Notification: ${message.notification?.title}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Handler para cuando la app está cerrada/background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _setupLocalNotifications();
    await _saveToken();
    _listenForeground();
    _listenTokenRefresh();
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission();
  }

  // 💾 Guardar token en Supabase
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

  // 🔄 Si el token cambia, actualizarlo
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

  // 🔔 Configurar notificaciones locales (para mostrarlas en foreground)
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // Canal de alta importancia para Android
    const channel = AndroidNotificationChannel(
      'allfood_channel',
      'AllFood Notificaciones',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // 👂 Mostrar notificación cuando la app está en primer plano
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

  Future<void> saveTokenForCurrentUser() async {
    await _saveToken();
  }
}
