import 'package:flutter/services.dart';

import 'bill_listener_box.dart';
import 'event_bus.dart';

class BillListenerService {
  // 单例实例
  static final BillListenerService _instance = BillListenerService._internal();

  // 私有构造函数
  BillListenerService._internal();

  // 提供静态的实例获取方法
  factory BillListenerService() {
    return _instance;
  }

//RegExp regExp = RegExp(r"(\d+(\.\d{1,2})?)");
  static RegExp regExp = RegExp(r"(\d+\.\d{2})");
  // 需要处理的包名
  static const List<String> allowPackageName = [
    'com.eg.android.AlipayGphone',
    'com.tencent.mm'
  ];
  // 关键字
  static const List<String> allowKeywords = ['交易', '支付'];

  bool _isInitialized = false;

  late MethodChannel platform;

  Future<void> init() async {
    if (!_isInitialized) {
      platform = const MethodChannel('notification_listener');
      _isInitialized = true;
    }
  }

  Future<void> startBillListenerService() async {
    await init();
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

    int? account;
    String consumeAccountText = "请选择";

    final bill = {
      "detailed": match.group(0),
      "account": account,
      "time": DateTime.fromMillisecondsSinceEpoch(postTime),
      "consumeAccountText": consumeAccountText,
      "selectedCategory": null,
      "consumeCategoryText": "请选择",
      "categoryId": null,
    };

    // 添加账单并发送事件
    await BillListenerBox().addBill(bill);
    bus.emit("bill_listener", bill);
  }

  Future<void> clearBillListenerBox() async {
    await BillListenerBox().clearBills();
  }

  Future<void> delBill(int index) async {
    await BillListenerBox().delBill(index);
  }
}
