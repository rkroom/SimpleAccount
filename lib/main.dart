import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'tools/bill_listener_service.dart';
import 'tools/config.dart';
import 'tools/routes.dart';
import 'tools/workmanager_tool.dart';

void main() async {
  // 初始化数据之前，需要调用WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  //初始化Hive
  //ConfigService会在不同的isolate中运行，为避免重复初始化 Hive.initFlutter需要在 Global.init 之前运行
  await Hive.initFlutter();

  //开启MethodChannel
  const platform = MethodChannel('notification_listener');

  //初始化Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode, // 调试模式下设置为 true
  );

  // 初始化数据之后再加载UI，以及账单监听服务
  await Global.init();
  var hasPermission =
      await platform.invokeMethod('checkNotificationPermission');

  if (hasPermission) {
    await BillListenerService().startBillListenerService();
  }

  runApp(const MyApp());
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
