import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  Future<void> initNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails('statistics', 'timing_statistics',
          importance: Importance.max, priority: Priority.high, showWhen: false);

  static const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  Future<void> showNotification(int id, String title, String body) async {
    await _flutterLocalNotificationsPlugin.show(
        id, title, body, platformChannelSpecifics);
  }
}