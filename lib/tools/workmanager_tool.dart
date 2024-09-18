import 'package:workmanager/workmanager.dart';

import 'config.dart';
import 'notification_service.dart';
import 'tools.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    var response = await periodicStatistics();

    await NotificationService().showNotification(0, "statistics",
        '昨日：${response['previousDayConsumption']}，今日：${response['todayConsumption']}，本月：${response['currentlyMonthConsumption']}');

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