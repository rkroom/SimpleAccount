import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

import 'tools/bill_listener_service.dart';
import 'tools/config.dart';
import 'tools/notification_service.dart';
import 'tools/routes.dart';
import 'tools/tools.dart';

void main() {
  // 初始化数据之前，需要调用WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  //开启MethodChannel
  const platform = MethodChannel('notification_listener');
  //初始化Workmanager
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode, // 调试模式下设置为 true
  );
  // 初始化 ReceivePort
  ReceivePort receivePort = ReceivePort();

  // 初始化数据之后再加载UI，以及账单监听服务
  Global.init().whenComplete(() {
    platform
        .invokeMethod('checkNotificationPermission')
        .then((hasPermission) async {
      if (hasPermission) {
        await BillListenerService().startBillListenerService();
      }
    });
    runApp(const MyApp());
  });
  // 监听来自 callbackDispatcher 的消息
  receivePort.listen((message) async {
    if (message is SendPort) {
      // 收到 SendPort 后，发送数据给 callbackDispatcher
      var consumption = await periodicStatistics();
      message.send(consumption);
    } else {
      debugPrint('Received from callbackDispatcher: $message');
    }
  });

  // 将 SendPort 传递给 callbackDispatcher
  IsolateNameServer.registerPortWithName(
    receivePort.sendPort,
    'main_send_port',
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  // 默认进入的页面
  String firstPage = '/';

  @override
  void initState() {
    super.initState();
    // 如果跳过loading，则进入主页
    // if (Global.jumpLoad) {
    //  firstPage = '/home';
    //Navigator.of(context)
    //    .pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
    //}
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记账',
      theme: ThemeData(
        useMaterial3: false,
        //primaryColor: const Color(0xff6200EE),
      ),
      initialRoute: firstPage,
      onGenerateRoute: onGenerateRoute,
    );
  }
}
