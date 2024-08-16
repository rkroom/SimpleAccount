import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_account/tools.dart';
import 'account.dart';
import 'add.dart';
import 'config.dart';
import 'statement.dart';

class BottomNavigationWidget extends StatefulWidget {
  const BottomNavigationWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return BottomNavigationWidgetState();
  }
}

class BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  // 设定进入时显示的模块
  int _currentIndex = 0;

  // 将各个模块添加到List
  List<Widget> pages = [];
  // 标题
  List titles = ["添加","账单", "账户"];
  @override
//initState是初始化函数，在绘制底部导航控件的时候就把这3个页面添加到list里面用于下面跟随标签导航进行切换显示
  void initState() {
    super.initState();

    pages
      ..add(const AddWidget())
      ..add(const StatementWidget())
      ..add(const AccountWidget());
  }

  @override
  Widget build(BuildContext context) {
    /*
    返回一个脚手架，里面包含两个属性，一个是底部导航栏，另一个就是主体内容
     */
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        /*actions: [
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  //会从context的父类开始找组件context.findAncestorStateOfType
                  //当前组件的context父组件是 MyApp 是没有 Scaffold，且没有drawer,因此无法打开
                  //Builder是一个StatelessWidget基础组件，只不过返回了自己的context，因此没问题
                  Scaffold.of(context).openDrawer();
                  //Scaffold.of(context).closeDrawer(); //关闭侧边栏
                  // Scaffold.of(context).openEndDrawer();//打开右侧侧边栏
                },
                icon: const Icon(Icons.table_rows_rounded),
                iconSize: 20,
              );
            },
          ),
        ],*/
        /*actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Handle the configuration button press
              //Navigator.of(context)
              //    .pushNamed('/manage')
              //    .then((value) => {});
              Scaffold.of(context).openDrawer();
            },
          ),
        ],*/
      ),
      endDrawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('管理'),
            ),
            ListTile(
              title: const Text('添加设置'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/manage').then((value) => {});
              },
            ),
            ListTile(
              title: const Text('账本管理'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context)
                    .pushNamed('/accountFile')
                    .then((value) => {});
              },
            ),
            ListTile(
              title: const Text('导出账本'),
              onTap: () async {
                PermissionStatus status = await Permission.storage.status;

                if (status != PermissionStatus.granted) {
                  PermissionStatus requestStatus =
                      await Permission.storage.request();
                  if (requestStatus != PermissionStatus.granted) {
                    return;
                  }
                }
                var targetFile =
                    File(join(Global.aSdCard, basename(Global.config!.path)));
                var sourceFile = File(Global.config!.path);
                try {
                  await sourceFile.copy(targetFile.path);
                  if (context.mounted) {
                    showNoticeSnackBar(context, '已导出到：${targetFile.path}');
                  }
                } catch (e) {
                  //print(e);
                  if (context.mounted) {
                    showNoticeSnackBar(context, '账本导出失败：$e');
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        //底部导航栏的创建需要对应的功能标签作为子项，每个子项包含一个图标和一个title。
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.plus_one,
            ),
            label: '记账',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.receipt,
            ),
            label: '账单',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.local_atm,
            ),
            label: '账户',
          ),
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
