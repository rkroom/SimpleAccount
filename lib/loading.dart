import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'database.dart';
import 'package:file_picker/file_picker.dart';
import 'config.dart';

class CreateDatabaseWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState(){
    return new CreateDatabaseWidgetState();
  }
}

class CreateDatabaseWidgetState extends State<CreateDatabaseWidget>{
  //文件名的控制器
  TextEditingController _fileNameController = TextEditingController();

  //密码的控制器
  TextEditingController _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      // 标题
      appBar:new AppBar(title:Text( "创建文件")),
      // 主体内容
      body: Column(
        // 以列布局，内容居中显示
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // 文本输入框，用以输入文件名
          TextField(
            decoration: InputDecoration(
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
            decoration: InputDecoration(
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
              FlatButton(
                child: Text("确定"),
                // 按钮样式
                color: Colors.blue,
                textColor: Colors.black,
                shape: RoundedRectangleBorder(
                    side: BorderSide(
                    color: Colors.white,
                    width: 1,
                    ),
                borderRadius: BorderRadius.circular(8)),
                // 点击按钮事件
                onPressed: ()async{
                  // 如果文件名大于1位且密码大于6位数
                  if( _fileNameController.text.length >=1 && _passController.text.length >= 6){
                    // 利用path_provider获取外部存储的位置
                    String sdCardDir = (await getExternalStorageDirectory()).path;
                    // 利用path拼接文件路径，拼接路径时利用trim()删除空格
                    String dbFilePath = join(sdCardDir,"${_fileNameController.text.trim()}.bd");
                    // 获取文件，用以判断文件是否存在，如果文件存在，且用户需要覆盖该文件则删除该文件再创建新文件
                    var file = new File(dbFilePath);
                    // 如果文件存在
                    if (file.existsSync()){
                      // 弹出对话框
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("提示"),
                          content: Text("存在同名文件，是否覆盖？"),
                          actions: <Widget>[
                            FlatButton(
                              child: Text("取消"),
                              onPressed: () => Navigator.of(context).pop(true), //关闭对话框
                            ),
                            FlatButton(
                              child: Text("覆盖"),
                              onPressed: ()async {
                                // 删除文件
                                file.deleteSync();
                                // 创建数据库
                                await createDatabase(dbFilePath, _passController.text);
                                // 创建配置文件
                                await createConfig(dbFilePath, _passController.text);
                                // 跳转到主页
                                Navigator.of(context).pushNamedAndRemoveUntil('/home',(Route<dynamic> route) => false); //跳转
                              },
                          ),
                        ],
                      ));
                    }else{
                      // 如果文件不存在则直接创建文件并跳转到首页
                      await createDatabase(dbFilePath, _passController.text);
                      // 创建配置文件
                      await createConfig(dbFilePath, _passController.text);
                      Navigator.of(context).pushNamedAndRemoveUntil('/home',(Route<dynamic> route) => false); //跳转
                    }
                  }else{
                    // 如果用户输入不符合规则（密码位数不够，未输入文件名...），则弹出对话框提示用户检查输入。
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('请检查输入'),
                      ));
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

class SelectDatabaseWidget extends StatefulWidget{
  //存放参数
  final arguments;
  SelectDatabaseWidget({this.arguments});

  @override
  State<StatefulWidget> createState(){
    return new SelectDatabaseWidgetState();
  }
}

class SelectDatabaseWidgetState extends State<SelectDatabaseWidget>{

  //密码的控制器
  TextEditingController _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar:new AppBar(title:Text( "打开文件")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text("文件"),
          // 将获取到的参数显示出来
          Text("${widget.arguments['filePath']}"),
          TextField(
            obscureText: true,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(10.0),
              icon: Icon(Icons.vpn_key),
              labelText: '密码',
              helperText: '请输入密码',
            ),
            autofocus: false,
            // 控制器
            controller: _passController,
          ),
          FlatButton(
              child: Text("确定"),
              color: Colors.blue,
              textColor: Colors.black,
              shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Colors.white,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8)),
              onPressed: () async {
                // 测试是否能够正确打开数据库，如果能够正确打开数据库则跳转到主页
                try {
                  var db = await selectDatabase(
                      widget.arguments['filePath'], _passController.text);
                  // 创建配置文件
                  await createConfig(widget.arguments['filePath'], _passController.text);
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home', (Route<dynamic> route) => false);
                } catch (e) {
                  // 如果不能正确打开数据库，则弹出对话框
                  showDialog(
                      context: context,
                      builder: (context) =>
                          AlertDialog(
                            content: Text("请检查输入"),));
                }
              }),
        ],
      )
    );
  }
}

// 加载页
class LoadingWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new LoadingWidgetState();
  }
}

class LoadingWidgetState extends State<LoadingWidget> {

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      // 以列布局
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // 以行布局
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            // 包含一个IconButton和一个MaterialButton
            IconButton(icon: Icon(Icons.folder_open, size: 40.0)),
            MaterialButton(
                child: Text(
                  "打开文件",
                  textScaleFactor: 2.0,
                ),
                onPressed: () async {
                  // 利用文件选择器选择文件
                  String filePath = await FilePicker.getFilePath();
                  // 如果选择了文件
                  if (filePath != null) {
                    // 导航跳转到密码输入页面，并且文件路径作为参数传递
                    Navigator.of(context).pushNamed('/selectdb', arguments: {
                      "filePath": filePath
                    });
                  }
                }),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            IconButton(icon: Icon(Icons.folder_open, size: 40.0)),
            MaterialButton(
                child: Text("创建文件", textScaleFactor: 2.0),
                onPressed: (){
                  Navigator.of(context).pushNamed("/createdb");
                }),
          ]),
        ],
      ),
    );
  }
}
