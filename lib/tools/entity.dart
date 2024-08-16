class Config{
  String path;
  String password;

  Config(this.path, this.password);

  // 从JSON转换
  Config.fromJson(Map<String, dynamic> json)
      :path = json['path'],
       password = json['password'];

  // 转换为JSON
  Map<String, dynamic> toJson() =>
      {
        'path': path,
        'password': password,
      };
}