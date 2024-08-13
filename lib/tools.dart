import 'dart:math';

import 'package:flutter/material.dart';

void showNoticeSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 1), // You can adjust the duration as needed
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

// 获取当前月份，由此计算本月收支
List<String> currentlyMonthDays() {
  DateTime date = DateTime.now();
  int year = date.year;
  int month = date.month;
  if (month.toString().length == 1) {
    month = int.parse("0$month");
  }
  DateTime lastDayOfCurrentMonth = DateTime(year, month + 1, 0);
  return [
    '$year-$month-01 00:00:00',
    '$year-$month-${lastDayOfCurrentMonth.day} 23:59:59',
  ];
}

List<String> previousMonthDays() {
  DateTime date = DateTime.now();
  int year = date.year;
  int month = date.month - 1;

  if (month == 0) {
    year--;
    month = 12;
  }

  if (month.toString().length == 1) {
    month = int.parse("0$month");
  }

  DateTime lastDayOfPreviousMonth = DateTime(year, month + 1, 0);

  return [
    '$year-$month-01 00:00:00',
    '$year-$month-${lastDayOfPreviousMonth.day} 23:59:59',
  ];
}

String generateRandomString(int length) {
  final random = Random();
    const availableChars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz';
  //const availableChars =
   //   'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final randomString = List.generate(length,
          (index) => availableChars[random.nextInt(availableChars.length)])
      .join();

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
