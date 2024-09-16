import 'package:hive/hive.dart';

import 'entity.dart';

class ConfigService {
  // 单例模式
  static final ConfigService _singleton = ConfigService._internal();
  factory ConfigService() => _singleton;
  ConfigService._internal();

  // 私有的 Box 实例以及 Future，用于延迟初始化
  static Future<Box>? _boxFuture;

  // 获取 Box 实例，使用延迟初始化
  Future<Box> get _box async {
    return _boxFuture ??= _initialize();
  }

  // 初始化 Hive Box
  Future<Box> _initialize() async {
    return await Hive.openBox('config');
  }

  // 获取数据库路径
  Future<String?> getDBPath() async {
    var box = await _box;
    return box.get("path", defaultValue: null);
  }

  // 设置数据库路径
  Future<void> setDBPath(String path) async {
    var box = await _box;
    await box.put("path", path);
  }

  // 获取数据库密码
  Future<String?> getDBPassword() async {
    var box = await _box;
    return box.get("password", defaultValue: null);
  }

  // 设置数据库密码
  Future<void> setDBPassword(String password) async {
    var box = await _box;
    await box.put("password", password);
  }

  Future<Config?> getConfig() async {
    var box = await _box;
    var path = box.get("path", defaultValue: null);
    if (path == null) {
      return null;
    }
    var password = box.get("password");
    return Config(path, password);
  }
}
