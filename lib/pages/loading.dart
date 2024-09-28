import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

import '../tools/config.dart';
import '../tools/db.dart';
import '../tools/tools.dart';

class CreateDatabaseWidget extends StatefulWidget {
  const CreateDatabaseWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return CreateDatabaseWidgetState();
  }
}

class CreateDatabaseWidgetState extends State<CreateDatabaseWidget> {
  //文件名的控制器
  final TextEditingController _fileNameController = TextEditingController();

  //密码的控制器
  final TextEditingController _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 标题
      appBar: AppBar(title: const Text("创建文件")),
      // 主体内容
      body: Column(
        // 以列布局，内容居中显示
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // 文本输入框，用以输入文件名
          TextField(
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(10.0),
              icon: Icon(Icons.note_add),
              labelText: '文件名',
              helperText: '请输入文件名',
            ),
            autofocus: false,
            // 通过controller可以调用用户输入的数据
            controller: _fileNameController,
          ),
          TextField(
            obscureText: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(10.0),
              icon: Icon(Icons.vpn_key),
              labelText: '密码',
              helperText: '请设定一个六位及以上的密码',
            ),
            autofocus: false,
            controller: _passController,
          ),
          Row(
            // 以行布局，将登陆按钮放置到画面右侧
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              // 按钮
              TextButton(
                child: const Text("确定"),
                // 点击按钮事件
                onPressed: () async {
                  // 如果文件名大于1位且密码大于6位数
                  if (_fileNameController.text.isNotEmpty &&
                      _passController.text.length >= 6) {
                    // 利用path拼接文件路径，拼接路径时利用trim()删除空格
                    String dbFilePath = join(Global.externalStorageDirectory,
                        "${_fileNameController.text.trim()}.bd");
                    // 获取文件，用以判断文件是否存在，如果文件存在，且用户需要覆盖该文件则删除该文件再创建新文件
                    var file = File(dbFilePath);
                    // 如果文件存在
                    if (file.existsSync()) {
                      // 弹出对话框
                      if (mounted) {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: const Text("提示"),
                                  content: const Text("存在同名文件，是否覆盖？"),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text("取消"),
                                      onPressed: () => Navigator.of(context)
                                          .pop(true), //关闭对话框
                                    ),
                                    TextButton(
                                      child: const Text("覆盖"),
                                      onPressed: () async {
                                        // 删除文件
                                        //file.deleteSync();
                                        // 创建数据库
                                        await DB().createDatabase(
                                            dbFilePath, _passController.text);
                                        // 创建配置文件
                                        await createConfig(
                                            dbFilePath, _passController.text);
                                        //重启应用
                                        //Restart.restartApp();
                                        // 跳转到主页
                                        if (context.mounted) {
                                          Navigator.of(context)
                                              .pushNamedAndRemoveUntil(
                                                  '/home',
                                                  (Route<dynamic> route) =>
                                                      false); //跳转
                                        }
                                      },
                                    ),
                                  ],
                                ));
                      }
                    } else {
                      // 如果文件不存在则直接创建文件并跳转到首页
                      await DB()
                          .createDatabase(dbFilePath, _passController.text);
                      // 创建配置文件
                      await createConfig(dbFilePath, _passController.text);
                      //重启应用
                      //Restart.restartApp();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/home', (Route<dynamic> route) => false); //跳转
                      }
                    }
                  } else {
                    // 如果用户输入不符合规则（密码位数不够，未输入文件名...），则弹出对话框提示用户检查输入。
                    showNoticeSnackBar(context, "请检查输入");
                  }
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}

class SelectDatabaseWidget extends StatefulWidget {
  //存放参数
  final dynamic arguments;
  const SelectDatabaseWidget({super.key, this.arguments});

  @override
  State<StatefulWidget> createState() {
    return SelectDatabaseWidgetState();
  }
}

class SelectDatabaseWidgetState extends State<SelectDatabaseWidget> {
  //密码的控制器
  final TextEditingController _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("导入账本")),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text("导入账本到程序，不会修改源文件"),
            Text("文件名：${widget.arguments['filePath'][1]}"),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(10.0),
                icon: Icon(Icons.vpn_key),
                labelText: '密码',
                helperText: '请输入密码',
              ),
              autofocus: false,
              // 控制器
              controller: _passController,
            ),
            TextButton(
                child: const Text("确定"),
                onPressed: () async {
                  // 测试是否能够正确打开数据库，如果能够正确打开数据库则跳转到主页
                  try {
                    // 测试数据库是否能够打开
                    var r = await DB().checkDBfile(
                        widget.arguments['filePath'][0], _passController.text);
                    //如果能够正常打开，则修改数据库及配置文件
                    if (r) {
                      await DB().changeDBfile(widget.arguments['filePath'][0],
                          _passController.text);
                      await createConfig(widget.arguments['filePath'][0],
                          _passController.text);
                      //Restart.restartApp();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/home', (Route<dynamic> route) => false);
                      }
                    } else {
                      if (context.mounted) {
                        showNoticeSnackBar(context, "请检查输入");
                      }
                    }
                  } catch (e) {
                    // 如果不能正确打开数据库，则弹出对话框
                    if (context.mounted) {
                      showNoticeSnackBar(context, "请检查输入");
                    }
                  }
                }),
          ],
        ));
  }
}

// 加载页
class LoadingWidget extends StatefulWidget {
  const LoadingWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return LoadingWidgetState();
  }
}

class LoadingWidgetState extends State<LoadingWidget> {
  static const TextScaler customTextScaler = TextScaler.linear(2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 以列布局
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // 以行布局
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            // 包含一个IconButton和一个MaterialButton
            IconButton(
              icon: const Icon(Icons.folder_open, size: 40.0),
              onPressed: () {},
            ),
            MaterialButton(
                child: const Text(
                  "导入账本",
                  textScaler: customTextScaler,
                ),
                onPressed: () async {
                  String? filePath;
                  String? fileName;
                  String? targetPath;
                  String? targetFileName;
                  // 利用文件选择器选择文件
                  if (mounted) {
                    PermissionStatus status = await Permission.storage.status;
                    if (status != PermissionStatus.granted) {
                      PermissionStatus requestStatus =
                          await Permission.storage.request();
                      if (requestStatus.isDenied) {
                        return;
                      } else if (requestStatus.isPermanentlyDenied) {
                        openAppSettings();
                        return;
                      }
                    }
                    var file =
                        (await FilePicker.platform.pickFiles())?.files.single;
                    filePath = file?.path;
                    fileName = file?.name;
                  }
                  // 如果选择了文件
                  if (mounted) {
                    if (filePath != null) {
                      targetFileName = fileName;
                      if (Platform.isAndroid) {
                        if ((File(join(
                                Global.externalStorageDirectory, fileName)))
                            .existsSync()) {
                          targetFileName =
                              "${fileName}_${generateRandomString(5)}";
                        }

                        var targetFile = File(join(
                            Global.externalStorageDirectory, targetFileName));
                        var sourceFile = File(filePath);
                        try {
                          await sourceFile.copy(targetFile.path);
                          targetPath = targetFile.path;
                        } catch (e) {
                          if (context.mounted) {
                            showNoticeSnackBar(context, '账本导入失败：$e');
                          }
                        }
                      }
                      // 导航跳转到密码输入页面，并且文件路径作为参数传递
                      if (context.mounted) {
                        Navigator.of(context)
                            .pushNamed('/selectdb', arguments: {
                          "filePath": [targetPath, fileName]
                        });
                      }
                    }
                  }
                }),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            IconButton(
              icon: const Icon(Icons.folder_open, size: 40.0),
              onPressed: () {},
            ),
            MaterialButton(
                child: const Text("创建文件", textScaler: customTextScaler),
                onPressed: () {
                  Navigator.of(context).pushNamed("/createdb");
                }),
          ]),
        ],
      ),
    );
  }
}
