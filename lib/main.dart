import 'package:flutter/material.dart';

import 'tools/config.dart';
import 'tools/routes.dart';

void main() async {
  // 初始化数据之前，需要调用WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据之后再加载UI，以及账单监听服务
  await Global.init();

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
