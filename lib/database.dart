import 'package:flutter_sqlcipher/sqlite.dart';

createDatabase(String path,String password)async {
  // 创建数据库，其参数为路径和密码
  var db = await SQLiteDatabase.openOrCreateDatabase(path, password: password);
  // 开始事务
  db.beginTransaction();
  try {
    // 创建表
    await db.execSQL("""CREATE TABLE "account_book" (
  "id" integer PRIMARY KEY AUTOINCREMENT NOT NULL,
  "types_id" integer,
  "flow" varchar(20) NOT NULL,
  "detailed" decimal NOT NULL,
  "account_info_id" integer NOT NULL,
  "aim_account_id" integer,
  "comment" varchar(255),
  "created" datetime NOT NULL DEFAULT (datetime('now','localtime')),
  "when_time" datetime NOT NULL DEFAULT (datetime('now','localtime')),
  "updated" datetime NOT NULL DEFAULT (datetime('now','localtime')),
  CONSTRAINT "fk_account_book_account_info_1" FOREIGN KEY("account_info_id") REFERENCES "account_info"("id"),
  CONSTRAINT "fk_account_book_account_category_specific_1" FOREIGN KEY("types_id") REFERENCES "account_category_specific"("id"),
  CONSTRAINT "fk_account_book_account_info_2" FOREIGN KEY("aim_account_id") REFERENCES "account_info"("id"))""");
    await db.execSQL(
        """CREATE INDEX "account_book_account_info_id_030de390" ON "account_book" ("account_info_id" ASC)""");
    await db.execSQL(
        """CREATE INDEX "account_book_aim_account_id_f5979f3c" ON "account_book" ("aim_account_id" ASC)""");
    await db.execSQL(
        """CREATE INDEX "account_book_types_id_5b535171" ON "account_book" ("types_id" ASC)""");
    await db.execSQL(
        """CREATE TRIGGER update_book_datetime_Trigger AFTER UPDATE On account_book BEGIN  UPDATE account_book SET updated = (datetime('now','localtime')) WHERE id = NEW.id; END""");
    await db.execSQL("""CREATE TABLE "account_category_first" (
          "id" integer PRIMARY KEY AUTOINCREMENT NOT NULL,
          "first_level" varchar(100) NOT NULL,
          "flow_sign" varchar(10) NOT NULL,
          "created" datetime NOT NULL DEFAULT (datetime('now','localtime')),
          "updated" datetime NOT NULL DEFAULT (datetime('now','localtime')))""");
    await db.execSQL("""CREATE TABLE "account_category_specific" (
          "id" integer PRIMARY KEY AUTOINCREMENT NOT NULL,
          "created" datetime NOT NULL DEFAULT (datetime('now','localtime')),
          "updated" datetime NOT NULL DEFAULT (datetime('now','localtime')),
          "parent_category_id" integer NOT NULL,
          "specific_category" varchar(10) NOT NULL,
          CONSTRAINT "fk_account_category_specific_account_category_first_1" FOREIGN KEY ("parent_category_id") REFERENCES "account_category_first" ("id"))""");
    await db.execSQL(
        """CREATE INDEX "account_category_specific_parent_category_id_fd8a3ed5" ON "account_category_specific" ("parent_category_id" ASC)""");
    await db.execSQL(
        """INSERT INTO "sqlite_sequence" (name, seq) VALUES ('account_category_specific', 1000)""");
    await db.execSQL("""CREATE TABLE "account_info" (
          "id" integer PRIMARY KEY AUTOINCREMENT NOT NULL,
          "name" varchar(30) NOT NULL,
          "amount" decimal NOT NULL DEFAULT 0,
          "type" varchar(15) NOT NULL,
          "created" datetime NOT NULL DEFAULT (datetime('now','localtime')),
          "updated" datetime NOT NULL DEFAULT (datetime('now','localtime')))""");
    await db.execSQL(
        """CREATE TRIGGER update_category_datetime_Trigger AFTER UPDATE On account_category_first BEGIN  UPDATE account_category_first SET updated = datetime('now','localtime') WHERE id = NEW.id; END""");
    await db.execSQL(
        """CREATE TRIGGER update_specific_datetime_Trigger AFTER UPDATE On account_category_specific BEGIN  UPDATE account_category_specific SET updated = datetime('now','localtime') WHERE id = NEW.id; END""");
    await db.execSQL(
        """CREATE TRIGGER update_account_datetime_Trigger AFTER UPDATE On account_info BEGIN  UPDATE account_info SET updated = datetime('now','localtime') WHERE id = NEW.id; END""");
    // 默认值
    await db.execSQL("""INSERT INTO "account_category_first"("id", "first_level", "flow_sign") VALUES (1, '食品酒水', 'consume')""");
    await db.execSQL("""INSERT INTO "account_category_first"("id", "first_level", "flow_sign") VALUES (2, '居家物业', 'consume')""");
    await db.execSQL("""INSERT INTO "account_category_first"("id", "first_level", "flow_sign") VALUES (3, '行车交通', 'consume')""");
    await db.execSQL("""INSERT INTO "account_category_first"("id", "first_level", "flow_sign") VALUES (4, '交流通讯', 'consume')""");
    await db.execSQL("""INSERT INTO "account_category_first"("id", "first_level", "flow_sign") VALUES (5, '休闲娱乐', 'consume')""");
    await db.execSQL("""INSERT INTO "account_category_first"("id", "first_level", "flow_sign") VALUES (6, '学习进修', 'consume')""");
    await db.execSQL("""INSERT INTO "account_category_first"("id", "first_level", "flow_sign") VALUES (7, '人情往来', 'consume')""");
    await db.execSQL("""INSERT INTO "account_category_first"("id", "first_level", "flow_sign") VALUES (8, '医疗保健', 'consume')""");
    await db.execSQL("""INSERT INTO "account_category_first"("id", "first_level", "flow_sign") VALUES (9, '衣服饰品', 'consume')""");
    await db.execSQL("""INSERT INTO "account_category_first"("id", "first_level", "flow_sign") VALUES (10, '金融保险', 'consume')""");
    await db.execSQL("""INSERT INTO "account_category_first"("id", "first_level", "flow_sign") VALUES (11, '其他杂项', 'consume')""");
    await db.execSQL("""INSERT INTO "account_category_first"("id", "first_level", "flow_sign") VALUES (12, '职业收入', 'income')""");
    await db.execSQL("""INSERT INTO "account_category_first"("id", "first_level", "flow_sign") VALUES (13, '其他收入', 'income')""");
    await db.execSQL("""INSERT INTO "account_info"("id", "name", "amount", "type") VALUES (1, '现金', 0, 'asset')""");
    await db.execSQL("""INSERT INTO "account_info"("id", "name", "amount", "type") VALUES (2, '银行', 0, 'asset')""");
    await db.execSQL("""INSERT INTO "account_info"("id", "name", "amount", "type") VALUES (3, '余额宝', 0, 'asset')""");
    await db.execSQL("""INSERT INTO "account_info"("id", "name", "amount", "type") VALUES (4, '财付通', 0, 'asset')""");
    await db.execSQL("""INSERT INTO "account_info"("id", "name", "amount", "type") VALUES (5, '微信', 0, 'asset')""");
    await db.execSQL("""INSERT INTO "account_info"("id", "name", "amount", "type") VALUES (6, '白条', 0, 'debt')""");
    await db.execSQL("""INSERT INTO "account_info"("id", "name", "amount", "type") VALUES (7, '花呗', 0, 'debt')""");
    await db.execSQL("""INSERT INTO "account_info"("id", "name", "amount", "type") VALUES (8, '信用卡', 0, 'debt')""");
    await db.execSQL("""INSERT INTO "account_info"("id", "name", "amount", "type") VALUES (9, '借呗', 0, 'debt')""");
    await db.execSQL("""INSERT INTO "account_info"("id", "name", "amount", "type") VALUES (10, '应付款项', 0, 'debt')""");
    await db.execSQL("""INSERT INTO "account_info"("id", "name", "amount", "type") VALUES (11, '应收款项', 0, 'asset')""");
    await db.execSQL("""INSERT INTO "account_info"("id", "name", "amount", "type") VALUES (12, '公司报销', 0, 'asset')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1001, 1, '早午晚餐')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1002, 1, '水果零食')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1003, 1, '饮料')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1004, 1, '调味')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1005, 1, '烟酒茶')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1006, 2, '日常用品')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1007, 2, '水电煤气')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1008, 2, '维修保养')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1009, 2, '物业管理')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1010, 2, '房租')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1011, 3, '公共交通')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1012, 3, '打车租车')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1013, 3, '私家车费用')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1014, 4, '手机费')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1015, 4, '上网费')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1016, 4, '邮寄费')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1017, 5, '电子产品')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1018, 5, '运动健身')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1019, 5, '腐败聚会')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1020, 5, '休闲玩乐')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1021, 5, '宠物宝贝')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1022, 5, '旅游度假')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1023, 6, '书报杂志')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1024, 6, '培训进修')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1025, 6, '数码装备')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1026, 6, '学费')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1027, 6, '学习用具')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1028, 6, '杂费')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1029, 7, '送礼请客')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1030, 7, '发红包')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1031, 7, '孝敬家长')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1032, 7, '慈善捐助')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1033, 8, '检查费')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1034, 8, '药品费')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1035, 8, '保健费')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1036, 8, '美容费')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1037, 8, '治疗费')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1038, 9, '衣服裤子')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1039, 9, '服饰配件')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1040, 9, '鞋帽包包')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1041, 9, '化妆饰品')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1042, 10, '银行手续')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1043, 10, '投资亏损')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1044, 10, '按揭还款')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1045, 10, '利息支出')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1046, 10, '赔偿罚款')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1047, 10, '保险')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1048, 11, '其他支出')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1049, 11, '意外丢失')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1050, 11, '烂账损失')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1051, 12, '工资收入')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1052, 12, '利息收入')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1053, 12, '加班收入')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1054, 12, '奖金收入')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1055, 12, '投资收入')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1056, 12, '兼职收入')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1057, 13, '礼金收入')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1058, 13, '中奖收入')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1059, 13, '意外来钱')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1060, 13, '经营所得')""");
    await db.execSQL("""INSERT INTO "account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1061, 13, '退款')""");
    // 事务成功标志
    db.setTransactionSuccessful();
  } catch (e) {

  } finally {
    // 结束事务
    db.endTransaction();
  }
}

selectDatabase(String path,String password)async {
  // 尝试打开数据库
  var db = await SQLiteDatabase.openDatabase(path, password: password);
  // 获取数据库打开状态
  bool isOpen = await db.isOpen;
  // 如果数据库打开了则返回数据库，如果没有正确打开则抛出错误，调用方可以用try..catch来处理错误。
  if (isOpen){
    return db;
  }else{
  throw "wrong";
  }
}

initDatabase(String path,String password)async{
  var db = await SQLiteDatabase.openDatabase(path, password: password);
  // 获取数据库打开状态
  bool isOpen = await db.isOpen;
  if(isOpen){
    return db;
  }else{
    return "err";
  }
}