import 'package:hive_flutter/hive_flutter.dart';

class BillListenerBox {
  static final BillListenerBox _singleton = BillListenerBox._internal();
  factory BillListenerBox() => _singleton;
  BillListenerBox._internal();

  static Box? _box;

  // 获取数据库实例，如果不存在则初始化
  Future<Box> get box async {
    // 如果数据库已经存在，返回它，否则初始化并返回
    return _box ??= await _initialize();
  }

  Future<Box> _initialize() async {
    await Hive.initFlutter();
    return await Hive.openBox('bill_listener');
  }

  Future<int> addBill(dynamic bill) async {
    var b = await box;
    return b.add(bill);
  }

  Future<void> delBill(int index) async {
    var b = await box;
    b.deleteAt(index);
  }

  Future<List> getBills() async {
    var b = await box;
    return b.values.toList();
  }

  Future<int> clearBills() async {
    var b = await box;
    return b.clear();
  }
}
