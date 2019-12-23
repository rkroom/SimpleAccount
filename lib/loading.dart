import 'package:flutter/material.dart';

// 加载页
class LoadingWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return new LoadingWidgetState();
  }
}

class LoadingWidgetState extends State<LoadingWidget>{
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      // 以列布局
      body: Column(
        mainAxisAlignment:MainAxisAlignment.center,
        children: <Widget>[
          // 以行布局
          Row(
              mainAxisAlignment:MainAxisAlignment.center,
              children:<Widget>[
                // 包含一个IconButton和一个MaterialButton
                IconButton(icon: Icon(Icons.folder_open,size: 40.0)),
                MaterialButton(child:Text("打开文件", textScaleFactor: 2.0,),onPressed: () {
                  // 导航跳转，跳转之前删除已存在的路由
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
                }),
              ]),
          Row(
              mainAxisAlignment:MainAxisAlignment.center,
              children:<Widget>[
                IconButton(icon: Icon(Icons.folder_open,size: 40.0)),
                MaterialButton(child:Text("创建文件", textScaleFactor: 2.0),onPressed: () {}),
              ]),
        ],
      ),
    );
  }
}