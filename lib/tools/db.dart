import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'config.dart';
import 'entity.dart';

class DB {
  static final DB _singleton = DB._internal();

  factory DB() {
    return _singleton;
  }

  DB._internal();

  static Database? _database;

  Future<Database> get database async =>
      _database ??= await _initDB(Global.config!.path, Global.config!.password);

  Future<Database> _initDB(path, password) async {
    return await openDatabase(path,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        password: password);
  }

  ///
  /// 创建Table
  ///
  Future _onCreate(Database db, int version) async {}

  ///
  /// 更新Table
  ///
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  //根据时间获取最常出现类目
  Future getMostFrequentType(String flow,
      {int interval = -30, int limit = 6}) async {
    var db = await database;
    return db.rawQuery("""WITH MaxDate as(
      SELECT max(when_time) as max_wt
       FROM books_account_book
       WHERE flow = ?
     ),
       TopValues as (
       SELECT types_id
       FROM books_account_book
       WHERE flow = ?
       AND when_time >= (SELECT date(max_wt, ?) FROM MaxDate)
       GROUP BY types_id
       ORDER BY COUNT(*) DESC
       LIMIT ?)
  SELECT s.specific_category category,s.id,s.parent_category_id pid
  from books_account_category_specific s
  JOIN TopValues t on s.id = t.types_id""",
        [flow, flow, "$interval days", limit]);
  }

  //根据时间获取最常用账户
  Future getMostFrequentAccount(String flow,
      {int interval = -30, int limit = 6}) async {
    var db = await database;
    return db.rawQuery("""WITH MaxDate as(
    SELECT max(when_time) as max_wt
     FROM books_account_book
     WHERE flow = ?
	 ),
     TopValues as (
     SELECT account_info_id
     FROM books_account_book
     WHERE flow = ?
     AND when_time >= (SELECT date(max_wt, ?) FROM MaxDate)
     GROUP BY account_info_id
     ORDER BY COUNT(*) DESC
     LIMIT ?)
SELECT a.name,a.id
from books_account_info a
JOIN TopValues t on a.id = t.account_info_id""",
        [flow, flow, "$interval days", limit]);
  }

  //根据支出/收入获取类目
  Future getCategorys(String flow) async {
    var db = await database;
    return db.rawQuery(
        """select s.id,specific_category,f.first_level as name 
        from books_account_category_specific as s 
        LEFT JOIN books_account_category_first as f on s.parent_category_id = f.id where f.flow_sign = ?""",
        [flow]);
  }

  //获取账户信息
  Future getAccounts() async {
    var db = await database;
    return db.rawQuery("SELECT id,name,type FROM books_account_info");
  }

  //添加支出/收入账单
  Future addBill(category, flow, detailed, account, comment, time) async {
    var db = await database;
    return db.rawInsert(
        "INSERT INTO books_account_book(types_id,flow,detailed,account_info_id,comment,when_time) values (?,?,?,?,?,?)",
        [
          category,
          flow,
          detailed,
          account,
          comment,
          time.substring(0, 19),
        ]);
  }

  //添加转账账单
  Future addTransfer(detailed, account, aimAccount, comment, when) async {
    var db = await database;
    return db.rawInsert(
        "INSERT INTO books_account_book(flow,detailed,account_info_id,aim_account_id,comment,when_time) values (?,?,?,?,?,?)",
        [
          "transfer",
          detailed,
          account,
          aimAccount,
          comment,
          when.substring(0, 19),
        ]);
  }

  //账单列表
  Future getBillDetails(pageSize, pageNum) async {
    var db = await database;
    return db.rawQuery(
        """select i.name as account,b.account_info_id as account_id, case when b.flow = 'consume' then '支出' when b.flow = 'income' then '收入' 
           when b.flow = 'transfer' then '转账' end as flow,i2.name as aim_account,b.aim_account_id,s.specific_category as category,b.comment,
           strftime('%Y-%m-%d %H:%M',b.when_time) as date,b.detailed,b.flow as flowSign,b.id from books_account_book as b left join books_account_info as i
           on b.account_info_id = i.id left join books_account_info as i2 on b.aim_account_id = i2.id left join books_account_category_specific as s on 
           b.types_id = s.id order by when_time desc limit ? offset ?""",
        [pageSize, pageNum]);
  }

  //删除账单
  Future deleteBill(id) async {
    var db = await database;
    return db.rawDelete("""DELETE  From books_account_book where id = ?""", [
      id,
    ]);
  }

  //获取账户信息
  Future getAccountInfo(pageSize, page) async {
    var db = await database;
    return db.rawQuery(
        """SELECT id,name,case when bai.type = 'asset' then '资产' when bai.type = 'debt' then '负债' end as type,cdetailed,idetailed,toutdetailed,tindetailed,amount,
           round((case when bai.type ='asset' then ifnull(idetailed,0)-ifnull(cdetailed,0)+ifnull(tindetailed,0)-ifnull(toutdetailed,0)+amount 
           when type = 'debt' then ifnull(cdetailed,0)-ifnull(idetailed,0)+ifnull(toutdetailed,0)-ifnull(tindetailed,0)-amount end),2) as balance 
           FROM books_account_info as bai 
           LEFT JOIN (SELECT account_info_id,sum(detailed) as  cdetailed 
           from books_account_book
           WHERE flow='consume' 
           GROUP by account_info_id) as c on c.account_info_id = bai.id 
           left join (SELECT account_info_id,sum(detailed) as  idetailed 
           from books_account_book 
           WHERE flow='income' 
           GROUP by account_info_id) as i on i.account_info_id = bai.id 
           left join (SELECT account_info_id,sum(detailed) as  toutdetailed 
           from books_account_book 
           WHERE flow='transfer'
           GROUP by account_info_id) as tout on tout.account_info_id = bai.id 
           left join (SELECT aim_account_id,sum(detailed) as  tindetailed 
           from books_account_book
           WHERE flow='transfer' 
           GROUP by aim_account_id) as tin on tin.aim_account_id = bai.id
           limit ? offset ?""", [pageSize, page]);
  }

  //更新账户名
  Future updateAccountName(name, id) async {
    var db = await database;
    return db.rawUpdate("UPDATE books_account_info set name = ? where id = ?", [
      name,
      id,
    ]);
  }

  //获取一级分类
  Future getFirstCategories() async {
    var db = await database;
    return db.rawQuery("select * from books_account_category_first", []);
  }

  //添加一级分类
  Future addFirstCategory(firstLevelName, flow) async {
    var db = await database;
    return db.rawInsert(
        "INSERT INTO books_account_category_first(first_level,flow_sign) values (?,?)",
        [firstLevelName, flow]);
  }

  //添加二级分类
  Future addSpecificCategory(superiorLevel, specificLevel) async {
    var db = await database;
    return db.rawInsert(
        "INSERT INTO books_account_category_specific(parent_category_id,specific_category) values (?,?)",
        [superiorLevel, specificLevel]);
  }

  //添加账户
  Future addAccount(name, amount, type) async {
    var db = await database;
    return db.rawInsert(
        "INSERT INTO books_account_info(name,amount,type) values (?,?,?)",
        [name, amount, type]);
  }

  //获取资产/负债总数
  Future totalBalance(type) async {
    var db = await database;
    return db.rawQuery(
        """select round(sum(balance),2) as balance from (SELECT ifnull(idetailed,0)-ifnull(cdetailed,0)+ifnull(tindetailed,0)-ifnull(toutdetailed,0)+amount as balance FROM books_account_info as bai 
           LEFT JOIN (SELECT account_info_id,sum(detailed) as  cdetailed from books_account_book WHERE flow='consume' GROUP by account_info_id) as c on c.account_info_id = bai.id 
           left join (SELECT account_info_id,sum(detailed) as  idetailed from books_account_book WHERE flow='income' GROUP by account_info_id) as i on i.account_info_id = bai.id 
           left join (SELECT account_info_id,sum(detailed) as  toutdetailed from books_account_book WHERE flow='transfer' GROUP by account_info_id) as tout on tout.account_info_id = bai.id 
           left join (SELECT aim_account_id,sum(detailed) as  tindetailed from books_account_book WHERE flow='transfer' GROUP by aim_account_id) as tin on tin.aim_account_id = bai.id 
           WHERE bai.type = ?)""", [type]);
  }

  //根据时间获取资产/负债总数
  Future timeStatistics(flow, startTime, endTime) async {
    var db = await database;
    return db.rawQuery(
        """SELECT round(sum(detailed),2) as amount FROM books_account_book WHERE flow = ? AND when_time > ? AND when_time < ?""",
        [flow, startTime, endTime]);
  }

  //根据时间获取一级分类消费情况
  Future getFirstLevelConsumeAnalysis(querydateStart, querydateEnd) async {
    var db = await database;
    return db.rawQuery(
        """SELECT round(sum(b.detailed),2) as value,f.first_level as name FROM books_account_book as b left JOIN 
           books_account_category_specific as s on b.types_id = s.id LEFT JOIN books_account_category_first as f on s.parent_category_id = f.id 
           WHERE flow='consume' AND when_time >= ? AND when_time <= ? GROUP BY parent_category_id""",
        [querydateStart, querydateEnd]);
  }

  //测试数据库文件
  Future checkDBfile(String path, String password) async {
    try {
      await openDatabase(path, password: password);
      return true;
    } catch (error) {
      return false;
    }
  }

  //修改数据库文件
  Future changeDBfile(String path, String password) async {
    _database = await _initDB(path, password);
    Global.config = Config(path, password);
    return _database!.isOpen;
  }

  //创建数据库
  Future createDatabase(String path, String password) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    try {
      File file = File(path);
      if (await file.exists()) {
        deleteDatabase(path);
      }
    } catch (error) {
      rethrow;
    }
    _database = await _initDB(path, password);
    await _database!.transaction((txn) async {
      // 创建表
      await txn.execute("""CREATE TABLE "app" (
      "id"	INTEGER,
      "key"	TEXT NOT NULL UNIQUE,
      "value"	TEXT NOT NULL,
      PRIMARY KEY("id" AUTOINCREMENT)
    )""");
      await txn.execute("""CREATE TABLE "books_account_book" (
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
          CONSTRAINT "fk_books_account_book_books_account_info_1" FOREIGN KEY("account_info_id") REFERENCES "books_account_info"("id"),
          CONSTRAINT "fk_books_account_book_books_account_category_specific_1" FOREIGN KEY("types_id") REFERENCES "books_account_category_specific"("id"),
          CONSTRAINT "fk_books_account_book_books_account_info_2" FOREIGN KEY("aim_account_id") REFERENCES "books_account_info"("id"))""");
      await txn.execute(
          """CREATE INDEX "books_account_book_account_info_id_030de390" ON "books_account_book" ("account_info_id" ASC)""");
      await txn.execute(
          """CREATE INDEX "books_account_book_aim_account_id_f5979f3c" ON "books_account_book" ("aim_account_id" ASC)""");
      await txn.execute(
          """CREATE INDEX "books_account_book_types_id_5b535171" ON "books_account_book" ("types_id" ASC)""");
      await txn.execute(
          """CREATE TRIGGER update_book_datetime_Trigger AFTER UPDATE On books_account_book BEGIN  UPDATE books_account_book SET updated = (datetime('now','localtime')) WHERE id = NEW.id; END""");
      await txn.execute("""CREATE TABLE "books_account_category_first" (
          "id" integer PRIMARY KEY AUTOINCREMENT NOT NULL,
          "first_level" varchar(100) NOT NULL,
          "flow_sign" varchar(10) NOT NULL,
          "created" datetime NOT NULL DEFAULT (datetime('now','localtime')),
          "updated" datetime NOT NULL DEFAULT (datetime('now','localtime')))""");
      await txn.execute("""CREATE TABLE "books_account_category_specific" (
          "id" integer PRIMARY KEY AUTOINCREMENT NOT NULL,
          "created" datetime NOT NULL DEFAULT (datetime('now','localtime')),
          "updated" datetime NOT NULL DEFAULT (datetime('now','localtime')),
          "parent_category_id" integer NOT NULL,
          "specific_category" varchar(10) NOT NULL,
          CONSTRAINT "fk_books_account_category_specific_books_account_category_first_1" FOREIGN KEY ("parent_category_id") REFERENCES "books_account_category_first" ("id"))""");
      await txn.execute(
          """CREATE INDEX "books_account_category_specific_parent_category_id_fd8a3ed5" ON "books_account_category_specific" ("parent_category_id" ASC)""");
      await txn.execute(
          """INSERT INTO "sqlite_sequence" (name, seq) VALUES ('books_account_category_specific', 1000)""");
      await txn.execute("""CREATE TABLE "books_account_info" (
          "id" integer PRIMARY KEY AUTOINCREMENT NOT NULL,
          "name" varchar(30) NOT NULL,
          "amount" decimal NOT NULL DEFAULT 0,
          "type" varchar(15) NOT NULL,
          "created" datetime NOT NULL DEFAULT (datetime('now','localtime')),
          "updated" datetime NOT NULL DEFAULT (datetime('now','localtime')))""");
      await txn.execute(
          """CREATE TRIGGER update_category_datetime_Trigger AFTER UPDATE On books_account_category_first BEGIN  UPDATE books_account_category_first SET updated = datetime('now','localtime') WHERE id = NEW.id; END""");
      await txn.execute(
          """CREATE TRIGGER update_specific_datetime_Trigger AFTER UPDATE On books_account_category_specific BEGIN  UPDATE books_account_category_specific SET updated = datetime('now','localtime') WHERE id = NEW.id; END""");
      await txn.execute(
          """CREATE TRIGGER update_account_datetime_Trigger AFTER UPDATE On books_account_info BEGIN  UPDATE books_account_info SET updated = datetime('now','localtime') WHERE id = NEW.id; END""");
      await txn.execute("""CREATE TABLE "diaries_diary_info" (
      "id" integer PRIMARY KEY AUTOINCREMENT NOT NULL,
      "diarydate" datetime NOT NULL DEFAULT (datetime('now','localtime')),
      "weather" varchar(30) NOT NULL,
      "title" varchar(30),
      "content" TEXT NOT NULL,
      "created" datetime NOT NULL DEFAULT (datetime('now','localtime')),
      "updated" datetime NOT NULL DEFAULT (datetime('now','localtime')))""");
      await txn.execute(
          """CREATE TRIGGER update_diary_datetime_Trigger AFTER UPDATE On diaries_diary_info BEGIN  UPDATE diaries_diary_info SET updated = (datetime('now','localtime')) WHERE id = NEW.id; END;""");
      await txn.execute("""CREATE TABLE "schemes_project_info" (
      "id" integer PRIMARY KEY AUTOINCREMENT NOT NULL,
      "created" datetime NOT NULL DEFAULT (datetime('now','localtime')),
      "type" varchar(30) NOT NULL,
      "content" TEXT NOT NULL,
      "finished" datetime,
      "amount" decimal,
      "finaldate" datetime,
      "status" varchar(30) NOT NULL,
      "round" varchar(30),
      "datesign" integer,
      "updated" datetime NOT NULL DEFAULT (datetime('now','localtime')),
      "recordtime" datetime NOT NULL DEFAULT (datetime('now','localtime')))""");
      await txn.execute(
          """CREATE TRIGGER update_schemes_datetime_Trigger AFTER UPDATE On schemes_project_info BEGIN  UPDATE schemes_project_info SET updated = (datetime('now','localtime')) WHERE id = NEW.id; END;""");
      await txn.execute("""CREATE TABLE "schemes_handle_info" (
      "id" integer PRIMARY KEY AUTOINCREMENT NOT NULL,
      "project_id" integer NOT NULL,
      "handledate" datetime NOT NULL DEFAULT (datetime('now','localtime')),
      "comment" TEXT,
      "recordtime" datetime NOT NULL DEFAULT (datetime('now','localtime')),
      "updated" datetime NOT NULL DEFAULT (datetime('now','localtime')),
      CONSTRAINT "fk_schemes_project_handle_info" FOREIGN KEY ("project_id") REFERENCES "schemes_project_info" ("id"))""");
      await txn.execute(
          """CREATE TRIGGER update_handle_datetime_Trigger AFTER UPDATE On schemes_handle_info BEGIN  UPDATE schemes_handle_info SET updated = (datetime('now','localtime')) WHERE id = NEW.id; END""");
      // 默认值
      await txn.execute(
          """INSERT INTO "books_account_category_first"("id", "first_level", "flow_sign") VALUES (1, '食品酒水', 'consume')""");
      await txn.execute(
          """INSERT INTO "books_account_category_first"("id", "first_level", "flow_sign") VALUES (2, '居家物业', 'consume')""");
      await txn.execute(
          """INSERT INTO "books_account_category_first"("id", "first_level", "flow_sign") VALUES (3, '行车交通', 'consume')""");
      await txn.execute(
          """INSERT INTO "books_account_category_first"("id", "first_level", "flow_sign") VALUES (4, '交流通讯', 'consume')""");
      await txn.execute(
          """INSERT INTO "books_account_category_first"("id", "first_level", "flow_sign") VALUES (5, '休闲娱乐', 'consume')""");
      await txn.execute(
          """INSERT INTO "books_account_category_first"("id", "first_level", "flow_sign") VALUES (6, '学习进修', 'consume')""");
      await txn.execute(
          """INSERT INTO "books_account_category_first"("id", "first_level", "flow_sign") VALUES (7, '人情往来', 'consume')""");
      await txn.execute(
          """INSERT INTO "books_account_category_first"("id", "first_level", "flow_sign") VALUES (8, '医疗保健', 'consume')""");
      await txn.execute(
          """INSERT INTO "books_account_category_first"("id", "first_level", "flow_sign") VALUES (9, '衣服饰品', 'consume')""");
      await txn.execute(
          """INSERT INTO "books_account_category_first"("id", "first_level", "flow_sign") VALUES (10, '金融保险', 'consume')""");
      await txn.execute(
          """INSERT INTO "books_account_category_first"("id", "first_level", "flow_sign") VALUES (11, '其他杂项', 'consume')""");
      await txn.execute(
          """INSERT INTO "books_account_category_first"("id", "first_level", "flow_sign") VALUES (12, '职业收入', 'income')""");
      await txn.execute(
          """INSERT INTO "books_account_category_first"("id", "first_level", "flow_sign") VALUES (13, '其他收入', 'income')""");
      await txn.execute(
          """INSERT INTO "books_account_info"("id", "name", "amount", "type") VALUES (1, '现金', 0, 'asset')""");
      await txn.execute(
          """INSERT INTO "books_account_info"("id", "name", "amount", "type") VALUES (2, '银行', 0, 'asset')""");
      await txn.execute(
          """INSERT INTO "books_account_info"("id", "name", "amount", "type") VALUES (3, '余额宝', 0, 'asset')""");
      await txn.execute(
          """INSERT INTO "books_account_info"("id", "name", "amount", "type") VALUES (4, '财付通', 0, 'asset')""");
      await txn.execute(
          """INSERT INTO "books_account_info"("id", "name", "amount", "type") VALUES (5, '微信', 0, 'asset')""");
      await txn.execute(
          """INSERT INTO "books_account_info"("id", "name", "amount", "type") VALUES (6, '白条', 0, 'debt')""");
      await txn.execute(
          """INSERT INTO "books_account_info"("id", "name", "amount", "type") VALUES (7, '花呗', 0, 'debt')""");
      await txn.execute(
          """INSERT INTO "books_account_info"("id", "name", "amount", "type") VALUES (8, '信用卡', 0, 'debt')""");
      await txn.execute(
          """INSERT INTO "books_account_info"("id", "name", "amount", "type") VALUES (9, '借呗', 0, 'debt')""");
      await txn.execute(
          """INSERT INTO "books_account_info"("id", "name", "amount", "type") VALUES (10, '应付款项', 0, 'debt')""");
      await txn.execute(
          """INSERT INTO "books_account_info"("id", "name", "amount", "type") VALUES (11, '应收款项', 0, 'asset')""");
      await txn.execute(
          """INSERT INTO "books_account_info"("id", "name", "amount", "type") VALUES (12, '公司报销', 0, 'asset')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1001, 1, '早午晚餐')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1002, 1, '水果零食')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1003, 1, '饮料')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1004, 1, '调味')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1005, 1, '烟酒茶')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1006, 2, '日常用品')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1007, 2, '水电煤气')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1008, 2, '维修保养')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1009, 2, '物业管理')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1010, 2, '房租')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1011, 3, '公共交通')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1012, 3, '打车租车')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1013, 3, '私家车费用')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1014, 4, '手机费')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1015, 4, '上网费')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1016, 4, '邮寄费')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1017, 5, '电子产品')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1018, 5, '运动健身')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1019, 5, '腐败聚会')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1020, 5, '休闲玩乐')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1021, 5, '宠物宝贝')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1022, 5, '旅游度假')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1023, 6, '书报杂志')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1024, 6, '培训进修')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1025, 6, '数码装备')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1026, 6, '学费')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1027, 6, '学习用具')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1028, 6, '杂费')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1029, 7, '送礼请客')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1030, 7, '发红包')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1031, 7, '孝敬家长')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1032, 7, '慈善捐助')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1033, 8, '检查费')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1034, 8, '药品费')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1035, 8, '保健费')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1036, 8, '美容费')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1037, 8, '治疗费')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1038, 9, '衣服裤子')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1039, 9, '服饰配件')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1040, 9, '鞋帽包包')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1041, 9, '化妆饰品')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1042, 10, '银行手续')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1043, 10, '投资亏损')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1044, 10, '按揭还款')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1045, 10, '利息支出')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1046, 10, '赔偿罚款')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1047, 10, '保险')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1048, 11, '其他支出')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1049, 11, '意外丢失')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1050, 11, '烂账损失')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1051, 12, '工资收入')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1052, 12, '利息收入')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1053, 12, '加班收入')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1054, 12, '奖金收入')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1055, 12, '投资收入')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1056, 12, '兼职收入')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1057, 13, '礼金收入')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1058, 13, '中奖收入')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1059, 13, '意外来钱')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1060, 13, '经营所得')""");
      await txn.execute(
          """INSERT INTO "books_account_category_specific"("id", "parent_category_id", "specific_category") VALUES (1061, 13, '退款')""");
      await txn.execute(
          """INSERT INTO "app"("key", "value") VALUES ('version','${packageInfo.version}')""");
    });
    Global.config = Config(path, password);
  }
}
