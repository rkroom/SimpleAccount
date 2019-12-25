import 'package:accounts/config.dart';
import 'package:flutter/material.dart';
import 'routes.dart';

void main(){
  // 初始化数据之前，需要调用WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化数据之后再加载UI
  Global.init().whenComplete((){
    runApp(new MyApp());
  });
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new MyAppState();
  }
}

class MyAppState extends State<MyApp> {

  // 默认进入的页面
  String firstPage = '/';

  @override
  void initState() {
    super.initState();
    // 如果跳过loading，则进入主页
    if(Global.jumpLoad){
      firstPage = '/home';
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: '记账',
        initialRoute: firstPage,
        onGenerateRoute: onGenerateRoute
    );
  }
}