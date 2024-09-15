import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'config_enum.dart';
import 'db.dart';

void showNoticeSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 2),
  );

  // 使用全局 ScaffoldMessenger 来显示 SnackBar
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

// 获取当前月份
List<String> currentlyMonthDays() {
  DateTime date = DateTime.now();
  int year = date.year;
  int month = date.month;

  // 使用 DateFormat 格式化月份
  DateFormat monthFormat = DateFormat('MM');
  monthFormat.format(DateTime(year, month));

  DateTime lastDayOfCurrentMonth = DateTime(year, month + 1, 0);

  // 使用 DateFormat 格式化日期时间
  DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  // 生成第一天和最后一天的时间字符串
  String firstDayFormatted =
      dateFormat.format(DateTime(year, month, 1, 0, 0, 0));
  String lastDayFormatted = dateFormat
      .format(DateTime(year, month, lastDayOfCurrentMonth.day, 23, 59, 59));
  return [firstDayFormatted, lastDayFormatted];
}

List<String> previousMonthDays() {
  DateTime date = DateTime.now();
  int year = date.year;
  int month = date.month - 1;

  if (month == 0) {
    year--;
    month = 12;
  }

  // 如果月份是单数位，添加前导0
  String formattedMonth = month.toString().padLeft(2, '0');

  DateTime lastDayOfPreviousMonth = DateTime(year, month + 1, 0);

  return [
    '$year-$formattedMonth-01 00:00:00',
    '$year-$formattedMonth-${lastDayOfPreviousMonth.day} 23:59:59',
  ];
}

String generateRandomString(int length) {
  final random = Random();
  const availableChars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz';
  //const availableChars =
  //   'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final randomString = List.generate(length,
      (index) => availableChars[random.nextInt(availableChars.length)]).join();

  return randomString;
}

// 查找元素索引的函数
List<int> findElementIndexes(List<dynamic> data, String targetElement) {
  List<int> result = [];
  for (int i = 0; i < data.length; i++) {
    var map = data[i];
    // 使用传统的 for 循环代替 forEach
    for (var entry in map.entries) {
      List<String> list = entry.value;
      for (int j = 0; j < list.length; j++) {
        if (list[j] == targetElement) {
          result.add(i); // 添加外层索引
          result.add(j); // 添加内层索引
          return result; // 找到后直接返回结果
        }
      }
    }
  }
  return result; // 如果没有找到元素，返回空列表
}

// 获取账户信息
Future getAccount() async {
  List list = (await DB().getAccounts()).toList();
  List accountName = [];
  Map accountIndex = {};
  Map accountType = {};
  for (var l in list) {
    accountName.add(l["name"]);
    accountIndex[l["name"]] = l["id"];
    accountType[l["id"]] = l["type"];
  }
  // 返回LIST，包含，账户名，账户ID，账户类型
  return [accountName, accountIndex, accountType];
}

// 获取分类
Future getCategory(String flow) async {
  /*
    查询数据库，并将结果转换为LIST，采用遍历将其转换LIST<MAP>形式的结构
     */
  // 查询数据库，并将结果转换为LIST
  List list = (await DB().getCategorys(flow)).toList();
  // category与对应Id的MAP
  Map categoryIndex = {};

  Map<String, List<String>> categoryMap = {};
  // 遍历结果
  for (var l in list) {
    String specificCategory = l['specific_category']!;
    String name = l['name']!;
    if (!categoryMap.containsKey(name)) {
      categoryMap[name] = [];
    }
    categoryMap[name]!.add(specificCategory);
    categoryIndex[l["specific_category"]] = l["id"];
  }
  //分类List
  List<Map<String, List<String>>> category = categoryMap.entries.map((entry) {
    return {entry.key: entry.value};
  }).toList();
  // LIST，包含分类和分类的ID
  return [category, categoryIndex];
}

/*
  void showCustomSnackBar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: 50.0, // 距离底部的位置
      left: 20.0,   // 可以根据需要调整位置
      right: 20.0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    ),
  );

  // 将 OverlayEntry 插入 Overlay
  overlay.insert(overlayEntry);

  // 自动移除自定义的 SnackBar
  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}*/

List<String> getThisWeekRange() {
  // 获取当前时间
  DateTime now = DateTime.now();

  // 计算当前日期是星期几 (星期一是1，星期天是7)
  int dayOfWeek = now.weekday;

  // 计算本周的周一日期
  DateTime startOfWeek = now.subtract(Duration(days: dayOfWeek - 1));

  // 计算本周的周日日期
  DateTime endOfWeek = now.add(Duration(days: 7 - dayOfWeek));

  // 设置日期格式
  DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  // 生成周一 00:00:00 和周日 23:59:59 的日期
  DateTime startOfWeekStart =
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0);
  DateTime endOfWeekEnd =
      DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);

  // 格式化日期
  String startOfWeekStr = formatter.format(startOfWeekStart);
  String endOfWeekStr = formatter.format(endOfWeekEnd);

  // 返回结果
  return [startOfWeekStr, endOfWeekStr];
}

List<String> getPreviousDayRange() {
  // 获取当前时间
  DateTime now = DateTime.now();

  // 获取前一天的日期
  DateTime previousDay = now.subtract(const Duration(days: 1));

  // 设置日期格式
  DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  // 生成前一天的开始和结束时间
  DateTime startOfDay =
      DateTime(previousDay.year, previousDay.month, previousDay.day, 0, 0, 0);
  DateTime endOfDay = DateTime(
      previousDay.year, previousDay.month, previousDay.day, 23, 59, 59);

  // 格式化日期
  String startOfDayStr = formatter.format(startOfDay);
  String endOfDayStr = formatter.format(endOfDay);

  // 返回结果
  return [startOfDayStr, endOfDayStr];
}

List<String> getTodayRange() {
  // 获取当前时间
  DateTime now = DateTime.now();

  // 生成今日的 00:00:00 的日期
  DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);

  // 设置日期格式
  DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  // 格式化日期
  String startOfDayStr = formatter.format(startOfDay);
  String nowStr = formatter.format(now);

  // 返回结果
  return [startOfDayStr, nowStr];
}

double checkDBresult(value) {
  if (value == null) {
    return 0;
  }
  if (value.isNaN) {
    return 0;
  }
  return value;
}

Future<Map> periodicStatistics() async {
  var cmd = currentlyMonthDays();
  var currentlyMonthConsumption = checkDBresult((await DB()
      .timeStatistics(Transaction.consume.value, cmd[0], cmd[1]))[0]["amount"]);
  var today = getTodayRange();
  var todayConsumption = checkDBresult((await DB().timeStatistics(
      Transaction.consume.value, today[0], today[1]))[0]["amount"]);
  var previousDay = getPreviousDayRange();
  var previousDayConsumption = checkDBresult((await DB().timeStatistics(
      Transaction.consume.value, previousDay[0], previousDay[1]))[0]["amount"]);
  return {
    "currentlyMonthConsumption": currentlyMonthConsumption,
    "todayConsumption": todayConsumption,
    "previousDayConsumption": previousDayConsumption
  };
}
