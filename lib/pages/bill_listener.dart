import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tools/bill_listener_service.dart';
import '../tools/event_bus.dart';
import '../tools/native_method_channel.dart';
import '../tools/tools.dart';
import '../tools/config_enum.dart';
import '../widgets/transactions.dart';
import '../widgets/quick_select.dart';

class BillListenerWidget extends StatefulWidget {
  const BillListenerWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return BillListenerWidgetState();
  }
}

class BillListenerWidgetState extends State<BillListenerWidget> {
  List notifications = [];
  List accounts = [];
  List categories = [];

  @override
  void initState() {
    super.initState();
    BillListenerService().getBills().then((value) {
      setState(() {
        notifications = value;
      });
      NativeMethodChannel.instance
          .setMethodCallHandler((MethodCall call) async {
        if (call.method == 'flutterPrint') {
          debugPrint(call.arguments);
          return;
        }
        if (call.method != 'onNotificationPosted') return;
        final String packageName = call.arguments['packageName'];
        final String content = call.arguments['content'];
        final String title = call.arguments['title'];
        final int postTime = call.arguments['postTime'];
        var bill = BillListenerService()
            .convertToBill(packageName, content, title, postTime);
        setState(() {
          notifications.add(bill);
        });
      });
    });

    // 初始化账户信息
    getAccount().then((list) {
      setState(() {
        accounts = list;
      });
    });
    getCategory("consume").then((list) {
      setState(() {
        categories = list;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (kDebugMode) {
      NativeMethodChannel.instance
          .setMethodCallHandler((MethodCall call) async {
        if (call.method == 'flutterPrint') {
          debugPrint(call.arguments);
        }
      });
    } else {
      NativeMethodChannel.instance.setMethodCallHandler(null);
    }
  }

  void _clearNotifications() async {
    await BillListenerService().clearBillListenerBox();
    setState(() {
      notifications = [];
    });
  }

  void _accountQuickSelect(dynamic item) {
    if (notifications.isEmpty) return;
    setState(() {
      notifications[0]["consumeAccountText"] = item["name"];
      notifications[0]["account"] = item["id"];
    });
  }

  void _categoryQuickSelect(dynamic item) {
    if (notifications.isEmpty) return;
    setState(() {
      notifications[0]["selectedCategory"] =
          findElementIndexes(categories[0], item['category']);
      notifications[0]["consumeCategoryText"] = item['category'];
      notifications[0]["categoryId"] = item["id"];
    });
  }

  @override
  Widget build(BuildContext context) {
    // 检查 accounts 是否为空
    if (accounts.isEmpty || categories.isEmpty) {
      return const CircularProgressIndicator(); // 或者显示加载动画等
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('账单'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clearNotifications,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: QuickSelect(
                accountQuickSelect: _accountQuickSelect,
                categoryQuickSelect: _categoryQuickSelect,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return Stack(children: [
                    Transactions(
                      //添加UniqueKey，否则删除时，只会删除最后一个元素
                      key: UniqueKey(),
                      amount: notifications[index]["detailed"],
                      flow: Transaction.consume,
                      accountNames: accounts[0],
                      accountIndexs: accounts[1],
                      categories: categories[0],
                      categoryIndex: categories[1],
                      time: notifications[index]["time"],
                      accountId: notifications[index]["account"],
                      accountText: notifications[index]["consumeAccountText"],
                      selectedCategory: notifications[index]
                          ["selectedCategory"],
                      categoryText: notifications[index]["consumeCategoryText"],
                      categoryId: notifications[index]["categoryId"],
                      addSuccess: (success) async {
                        if (success) {
                          await BillListenerService().delBill(index);
                          bus.emit("add_bill_success");
                          setState(() {
                            notifications.removeAt(index);
                          });
                        }
                      },
                      onAmountChanged: (value) {
                        notifications[index]["detailed"] = value;
                      },
                      onCategoryConfirm: (category) {
                        notifications[index]["selectedCategory"] =
                            category["selected"];
                        notifications[index]["consumeCategoryText"] =
                            category["text"];
                        notifications[index]["categoryId"] =
                            category["categoryId"];
                      },
                      onAccountConfirm: (account) {
                        notifications[index]["account"] = account["accountId"];
                        notifications[index]["consumeAccountText"] =
                            account["text"];
                      },
                      onTimeChanged: (time) {
                        notifications[index]["time"] = time;
                      },
                    ),
                    Positioned(
                      top: 0.0, // 调整按钮与顶部的距离
                      right: 8.0, // 调整按钮与右侧的距离
                      child: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await BillListenerService().delBill(index);
                          setState(() {
                            notifications.removeAt(index);
                          });
                        },
                      ),
                    ),
                  ]);
                },
              ),
            ),
          ],
        ));
  }
}
