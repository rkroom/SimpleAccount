import 'package:flutter/services.dart';

import 'bill_listener_box.dart';
import 'event_bus.dart';
import 'tools.dart';

class BillListenerService {
  late MethodChannel platform;

//RegExp regExp = RegExp(r"(\d+(\.\d{1,2})?)");
  RegExp regExp = RegExp(r"(\d+\.\d{2})");
  // 需要处理的包名
  static const List<String> allowPackageName = [
    'com.eg.android.AlipayGphone',
    'com.tencent.mm'
  ];
  // 关键字
  static const List<String> allowKeywords = ['交易', '支付'];

  late List accounts;

  void init() async {
    platform = const MethodChannel('notification_listener');
    accounts = await getAccount();
  }

  void startBillListenerService() {
    platform.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    // 检查是否是需要处理的调用方法
    if (call.method != 'onNotificationPosted') return;

    // 提取参数
    final packageName = call.arguments['packageName'];
    final content = call.arguments['content'];
    final title = call.arguments['title'];
    final postTime = call.arguments['postTime'];

    if (!allowPackageName.contains(packageName)) return;
    if (!allowKeywords.any((str) => title.contains(str))) return;

    // 匹配正则表达式
    final RegExpMatch? match = regExp.firstMatch(content);
    if (match == null) return;

    final bill = {
      "detailed": match.group(0),
      "account": null,
      "time": DateTime.fromMillisecondsSinceEpoch(postTime),
      "consumeAccountText": "请选择",
      "selectedCategory": null,
      "consumeCategoryText": "请选择",
      "categoryId": null,
    };

    // 添加账单并发送事件
    await BillListenerBox().addBill(bill);
    bus.emit("bill_listener", bill);
  }

  void clearBillListenerBox() async {
    await BillListenerBox().clearBills();
  }

  void delBill(int index) async {
    await BillListenerBox().delBill(index);
  }
}
