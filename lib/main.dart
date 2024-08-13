import 'package:simple_account/config.dart';
import 'package:flutter/material.dart';
import 'routes.dart';

void main() {
  // 初始化数据之前，需要调用WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化数据之后再加载UI
  Global.init().whenComplete(() {
    runApp(const MyApp());
  });
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
