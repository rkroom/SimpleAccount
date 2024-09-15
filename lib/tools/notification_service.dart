import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import 'config.dart';

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

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // 从 IsolateNameServer 获取主 Isolate 的 SendPort
    final SendPort? mainSendPort =
        IsolateNameServer.lookupPortByName('main_send_port');

    if (mainSendPort != null) {
      // 创建用于接收来自主 Isolate 响应的 ReceivePort
      ReceivePort callbackReceivePort = ReceivePort();

      // 将 callbackReceivePort 的 SendPort 发送给主 Isolate，请求数据
      mainSendPort.send(callbackReceivePort.sendPort);

      // 等待主 Isolate 返回的数据
      await for (var response in callbackReceivePort) {
        // 处理返回的数据
        debugPrint('Received data from main Isolate: ${response.toString()}');
        await NotificationService().showNotification(0, "statistics",
            '昨日：${response['previousDayConsumption']}，今日：${response['todayConsumption']}，本月：${response['currentlyMonthConsumption']}');
        callbackReceivePort.close();
        break;
      }
    } else {
      debugPrint('Failed to communicate with main isolate');
    }

    // 在任务执行完后重新注册下次任务
    scheduleDailyTask();
    return Future.value(true);
  });
}

void scheduleDailyTask() {
  // 获取当前时间
  DateTime now = DateTime.now();

  // 下一个时间
  DateTime nextTime = DateTime(
      now.year,
      now.month,
      now.day,
      Global.notificationTime['hour'],
      Global.notificationTime['minute'],
      Global.notificationTime['second']);

  // 如果当前时间已经过了设定时间，设置为明天的同一时间
  if (now.isAfter(nextTime)) {
    nextTime = nextTime.add(const Duration(days: 1));
  }

  // 计算当前时间到设定时间的时间差
  Duration initialDelay = nextTime.difference(now);

  //取消之前任务，避免重复执行
  Workmanager().cancelByUniqueName("dailyTask").then((_) {
    // 注册一次性任务，延迟到设定时间
    Workmanager().registerOneOffTask(
      "dailyTask", // 唯一的任务名，确保不会重复注册
      "dailyNotificationTask",
      initialDelay: initialDelay,
      existingWorkPolicy: ExistingWorkPolicy.replace, // 确保旧任务被替换
    );
  });
}
