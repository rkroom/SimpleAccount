import 'package:flutter/material.dart';
import 'account.dart';
import 'add.dart';
import 'statement.dart';

class BottomNavigationWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new BottomNavigationWidgetState();
  }
}

class BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  // 设定进入时显示的模块
  int _currentIndex = 0;

  // 将各个模块添加到List
  List<Widget> pages = new List();
  @override
//initState是初始化函数，在绘制底部导航控件的时候就把这3个页面添加到list里面用于下面跟随标签导航进行切换显示
  void initState() {
    pages
      ..add(StatementWidget())
      ..add(AddWidget())
      ..add(AccountWidget());
  }

  @override
  Widget build(BuildContext context) {
    /*
    返回一个脚手架，里面包含两个属性，一个是底部导航栏，另一个就是主体内容
     */
    return new Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        //底部导航栏的创建需要对应的功能标签作为子项，每个子项包含一个图标和一个title。
        items: [
          BottomNavigationBarItem(
              icon: Icon(
                Icons.receipt,
              ),
              title: new Text(
                '账单',
              )),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.plus_one,
              ),
              title: new Text(
                '记账',
              )),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.local_atm,
              ),
              title: new Text(
                '账户',
              )),
        ],
        //这是底部导航栏自带的位标属性，表示底部导航栏当前处于哪个导航标签。给他一个初始值0，也就是默认第一个标签页面。
        currentIndex: _currentIndex,
        //这是点击属性，会执行带有一个int值的回调函数，这个int值是系统自动返回的你点击的那个标签的位标
        onTap: (int i) {
          //进行状态更新，将系统返回的你点击的标签位标赋予当前位标属性，告诉系统当前要显示的导航标签被用户改变了。
          setState(() {
            _currentIndex = i;
          });
        },
      ),
    );
  }
}