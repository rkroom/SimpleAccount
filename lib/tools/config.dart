import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'entity.dart';

// 创建配置文件
createConfig(String path, String password) async {
  // 获取应用数据目录，应用卸载后会删除该目录
  String appDir = (await getApplicationDocumentsDirectory()).path;
  // 拼接配置文件路径
  String configPath = join(appDir, "config.json");
  File configFile = File(configPath);
  // 生成配置实体
  var json = Config(path, password);
  // 将实体序列化并写入文件
  configFile.writeAsStringSync(jsonEncode(json));
}

// 获取配置文件
Future getConfig() async {
  String appDir = (await getApplicationDocumentsDirectory()).path;
  String configPath = join(appDir, "config.json");
  File configFile = File(configPath);
  String jsonStr;
  // 如果文件存在则读取文件，如果不存在则返回null
  if (configFile.existsSync()) {
    jsonStr = configFile.readAsStringSync();
  } else {
    return null;
  }
  // 如果配置文件且有内容，则返回配置信息
  if (jsonStr.isNotEmpty) {
    var json = jsonDecode(jsonStr);
    // 将json转换为实体类
    var configJson = Config.fromJson(json);
    return configJson;
  } else {
    return null;
  }
}

// 全局变量，用以储存全局需要用到的信息
class Global {
  // 配置信息
  static Config? config;
  // 是否跳过Loading页
  static bool jumpLoad = false;

  static String aSdCard = "/sdcard/Download/";
  static late String externalStorageDirectory;

  static Future init() async {
    externalStorageDirectory = (await getExternalStorageDirectory())!.path;
    config = await getConfig();
    if (config == null) {
      jumpLoad = false;
    } else {
      jumpLoad = true;
    }
  }

}

