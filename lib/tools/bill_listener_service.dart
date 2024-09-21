import 'dart:convert';

import 'native_method_channel.dart';
import 'tools.dart';

class BillListenerService {
  // 单例实例
  static final BillListenerService _instance = BillListenerService._internal();

  // 私有构造函数
  BillListenerService._internal() {
    init();
  }

  // 提供静态的实例获取方法
  factory BillListenerService() {
    return _instance;
  }

  static RegExp regExp = RegExp(r"(\d+\.\d{2})");

  late List accounts;

  Future<void> init() async {
    accounts = await getAccount();
  }

  Future<void> clearBillListenerBox() async {
    await NativeMethodChannel.instance.clearBills();
  }

  Future<void> delBill(int index) async {
    await NativeMethodChannel.instance.delBill(index);
  }

  Future<List> getBills() async {
    List billsNotification = await NativeMethodChannel.instance.getBills();
    List bills = [];
    for (var notification in billsNotification) {
      bills.add(handlerBillString(notification));
    }

    return bills;
  }

  Map? handlerBillString(String notificationString) {
    Map<String, dynamic> notification = jsonDecode(notificationString);
    // 提取参数
    final String packageName = notification['packageName'];
    final String content = notification['content'];
    final String title = notification['title'];
    final int postTime = notification['postTime'];
    return convertToBill(packageName, content, title, postTime);
  }

  Map? convertToBill(
      String packageName, String content, String title, int postTime) {

    // 匹配正则表达式
    final RegExpMatch? match = regExp.firstMatch(content);

    int? account;
    String consumeAccountText = "请选择";

    final bill = {
      "detailed": match?.group(0),
      "account": account,
      "time": DateTime.fromMillisecondsSinceEpoch(postTime),
      "consumeAccountText": consumeAccountText,
      "selectedCategory": null,
      "consumeCategoryText": "请选择",
      "categoryId": null,
    };
    return bill;
  }
}
