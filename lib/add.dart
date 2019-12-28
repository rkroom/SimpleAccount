import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_picker/flutter_picker.dart';

import 'config.dart';

class AddWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new AddWidgetState();
  }
}

class AddWidgetState extends State<AddWidget> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  // 标签
  final tabs = ["支出", "收入", "转账"];

  // 记录时间
  DateTime whenTime = DateTime.now();
  // 支出功能变量
  List consumeCategory = new List();
  List selectedConsumeCategory = List<int>();
  String showConsumeCategory = "请选择";
  Map consumeCategoryIndex = new Map();
  int consumeCategoryId;
  TextEditingController _consumeAmountController = TextEditingController();
  TextEditingController _consumeCommentController = TextEditingController();
  // 收入功能变量
  List incomeCategory = new List();
  List selectedIncomeCategory = List<int>();
  String showIncomeCategory = "请选择";
  Map incomeCategoryIndex = new Map();
  int incomeCategoryId;
  TextEditingController _incomeAmountController = TextEditingController();
  TextEditingController _incomeCommentController = TextEditingController();
  // 转账功能变量
  String showConsumeAccount = "请选择";
  int consumeAccountId;
  String showIncomeAccount = "请选择";
  int incomeAccountId;
  String showTransferAccount = "请选择";
  int transferAccountId;
  String showTransferAimAccount = "请选择";
  int transferAimAccountId;
  TextEditingController _transferAmountController = TextEditingController();
  TextEditingController _transferCommentController = TextEditingController();
  // 账户信息功能
  List accountName = new List();
  Map accountIndex = new Map();
  Map accountType = new Map();



// 获取分类
  Future getCategory(String flow) async {
    /*
    查询数据库，并将结果转换为LIST，采用遍历将其转换LIST<MAP>形式的结构
     */
    // 查询数据库，并将结果转换为LIST
    List list = (await Global.db.rawQuery(
            "select s.id,s.parent_category_id,s.specific_category,f.first_level from account_category_specific as s left join  account_category_first as f on s.parent_category_id = f.id  WHERE f.flow_sign = ?",
            [flow]))
        .toList();
    // 一级分类ID
    int tempParentId = list[0]["parent_category_id"];
    // 一级分类
    String tempFirstLevel = list[0]["first_level"];
    // 临时LIST
    List tempList = new List();
    // 分类LIST
    List category = new List();
    // 临时MAP
    Map tempMap = new Map();
    // category与对应Id的MAP
    Map categoryIndex = new Map();
    // 遍历结果
    list.forEach((l) {
      categoryIndex[l["specific_category"]] = l["id"];
      // 如果一级分类相同
      if (l["parent_category_id"] == tempParentId) {
        // 将具体的分类添加到一个LIST
        tempList.add('"' + l["specific_category"] + '"');
      } else {
        // 如果一级分类不同
        // dart:convert转换JSON需要LIST中的MAP的键（KEY）为字符串，这里为其添加了“"”符号
        tempMap['"' + tempFirstLevel + '"'] = tempList.toString();
        // 将临时MAP添加到分类LIST中，要转换为STRING，避免引用传递导致的问题
        category.add(tempMap.toString());
        // 清空临时MAP
        tempMap.clear();
        // 清空临时LIST
        tempList.clear();
        tempList.add('"' + l["specific_category"] + '"');
        tempParentId = l["parent_category_id"];
        tempFirstLevel = l["first_level"];
      }
      // 如果是遍历的最后一次（最后的一级分类不会发生改变）
      if (l == list.last) {
        // 将分类添加到临时MAP
        tempMap['"' + tempFirstLevel + '"'] = tempList.toString();
        // 添加到分类LIST
        category.add(tempMap.toString());
      }
    });
    // LIST，包含分类和分类的ID
    return [category, categoryIndex];
  }
// 获取账户信息
  Future getAccount() async {
    List list =
        (await Global.db.rawQuery("SELECT id,name,type FROM account_info"))
            .toList();
    List accountName = new List();
    Map accountIndex = new Map();
    Map accountType = new Map();
    list.forEach((l) {
      accountName.add('"' + l["name"] + '"');
      accountIndex[l["name"]] = l["id"];
      accountType[l["id"]] = l["type"];
    });
    // 返回LIST，包含，账户名，账户ID，账户类型
    return [accountName, accountIndex, accountType];
  }

  @override
  void initState() {
    super.initState();
    // 初始化消费分类信息
    // 在initState方法中不能使用async，这里可以采用.then
    getCategory("consume").then((list) {
      consumeCategory = list[0];
      consumeCategoryIndex = list[1];
    });
    // 初始化收入分类信息
    getCategory("income").then((list) {
      incomeCategory = list[0];
      incomeCategoryIndex = list[1];
    });
    // 初始化账户信息
    getAccount().then((list) {
      accountName = list[0];
      accountIndex = list[1];
      accountType = list[2];
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // 通过DefaultTabController将tabBar和tabBarView联系
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        // 将标签显示在appbar处
        appBar: PreferredSize(
          // 该appbar的高度，你可以自行设置一个值
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Container(
            // 背景颜色
            color: Theme.of(context).primaryColor,
            child: Column(
              children: <Widget>[
                // 获取标签
                getTabBar(),
              ],
            ),
          ),
        ),
        body: getTabBarPages(),
      ),
    );
  }

// 获取标签
  Widget getTabBar() {
    // 返回TabBar
    return TabBar(
      tabs: tabs.map((t) {
        return Tab(
          child: Text(t),
        );
      }).toList(),
    );
  }

//支出，收入，转账分别的页面。
  //支出
  Widget consume() {
    return Center(
      // todo 将其抽离为组件
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("金额："),
              Container(
                width: 100,
                child: TextField(
                  //只允许输入小数
                  inputFormatters: [
                    WhitelistingTextInputFormatter(RegExp("[0-9.]")),
                  ],
                  keyboardType: TextInputType.number,
                  // 通过controller可以调用用户输入的数据
                  controller: _consumeAmountController,
                ),
              ),
            ],
          ),
          GestureDetector( // 手势
            behavior: HitTestBehavior.opaque,
            onTap: () async { //点击事件
              // 支出类别
              new Picker(
                // 打开时选择默认选择的分类，其类型为list
                  selecteds: selectedConsumeCategory,
                  // 选择器
                  adapter: PickerDataAdapter<String>(
                      pickerdata: new JsonDecoder()
                          .convert(consumeCategory.toString())),
                  changeToFirst: true,
                  hideHeader: false,
                  // 当点击确认按钮时
                  onConfirm: (Picker picker, List value) {
                    setState(() {
                      // 将默认值修改为本次的选择，下次打开时，其值为本次的选择
                      selectedConsumeCategory = value;
                      // 显示于界面的变量
                      showConsumeCategory = picker.adapter.text;
                      // 设置支出分类的ID
                      consumeCategoryId = consumeCategoryIndex[
                          picker.adapter.getSelectedValues()[1]];
                    });
                  }).showModal(this.context);
            },
            // 界面显示
            child: Text("类目：$showConsumeCategory"),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // 账户类别
              new Picker(
                  adapter: PickerDataAdapter<String>(
                      pickerdata:
                          new JsonDecoder().convert(accountName.toString())),
                  hideHeader: false,
                  onConfirm: (Picker picker, List value) {
                    setState(() {
                      // 显示于界面
                      showConsumeAccount = picker.adapter.text;
                      // 设置支出账户的ID
                      consumeAccountId = accountIndex[picker.adapter.getSelectedValues()[0]];
                    });
                  }).showModal(this.context);
            },
            child: Text("账户：$showConsumeAccount"),
          ),
          // 手势检测器
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            // 当单击时
            onTap: () {
              // 日期时间选择器
              DatePicker.showDateTimePicker(context, showTitleActions: true,
                  onConfirm: (date) {
                    setState(() {
                      // 设置记录时间
                      whenTime = date;
                    });
                  },
                  // 打开时显示的时间
                  currentTime: whenTime,
                  // 语言
                  locale: LocaleType.zh);
            },
            child: Text(
              // 对日期时间进行格式化
                "时间：${whenTime.year.toString()}-${whenTime.month.toString()
                    .padLeft(2, '0')}-${whenTime.day.toString().padLeft(
                    2, '0')} ${whenTime.hour.toString().padLeft(
                    2, '0')}:${whenTime.minute.toString().padLeft(2, '0')}"),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("备注："),
              // 使用Container包裹，以组装TextField
              Container(
                width: 150,
                child: TextField(
                  keyboardType: TextInputType.number,
                  // 通过controller可以调用用户输入的数据
                  controller: _consumeCommentController,
                ),
              ),
            ],
          ),
          FlatButton( //按钮
              child: Text("添加"),
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
              onPressed: () async {
                // 利用事务提交到数据库
                Global.db.beginTransaction();
                try {
                  // 如果没有输入金额，则抛出错误
                  if(_consumeAmountController.text.length == 0 ){
                    throw "need amount";
                  }
                  await Global.db.execSQL(
                      'INSERT INTO account_book(types_id,flow,detailed,account_info_id,comment,when_time) values (?,?,?,?,?,?)',
                      [
                        consumeCategoryId,
                        "consume",
                        _consumeAmountController.text,
                        consumeAccountId,
                        _consumeCommentController.text,
                        whenTime.toString()
                      ]);
                  // 如果账户类型为asset
                  if(accountType[consumeAccountId] == 'asset'){
                    await Global.db.execSQL(
                        "UPDATE account_info set amount = amount - ? where id = ?",
                        [
                          _consumeAmountController.text,
                          consumeAccountId
                        ]);
                  }else{
                    await Global.db.execSQL(
                        "UPDATE account_info set amount = amount + ? where id = ?",
                        [
                          _consumeAmountController.text,
                          consumeAccountId
                        ]);
                  }
                  await Global.db.setTransactionSuccessful();
                  // 清空金额和备注
                  _consumeAmountController.clear();
                  _consumeCommentController.clear();
                } catch (e) {
                  // 如果未能成功提交，则弹出检查输入
                  showDialog(
                      context: context,
                      builder: (context) =>
                          AlertDialog(
                            content: Text("请检查输入"),));
                } finally {
                  await Global.db.endTransaction();
                }
              }
          ),
        ],
      ),
    );
  }

  //收入
  Widget income() {
    return Center(
      // todo 将其抽离为组件
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("金额："),
              Container(
                width: 100,
                child: TextField(
                  //只允许输入小数
                  inputFormatters: [
                    WhitelistingTextInputFormatter(RegExp("[0-9.]")),
                  ],
                  keyboardType: TextInputType.number,
                  // 通过controller可以调用用户输入的数据
                  controller: _incomeAmountController,
                ),
              ),
            ],
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              // 支出类别
              new Picker(
                  selecteds: selectedIncomeCategory,
                  adapter: PickerDataAdapter<String>(
                      pickerdata: new JsonDecoder()
                          .convert(incomeCategory.toString())),
                  changeToFirst: true,
                  hideHeader: false,
                  onConfirm: (Picker picker, List value) {
                    setState(() {
                      selectedIncomeCategory = value;
                      showIncomeCategory = picker.adapter.text;
                      incomeCategoryId = consumeCategoryIndex[
                      picker.adapter.getSelectedValues()[1]];
                    });
                  }).showModal(this.context);
            },
            child: Text("类目：$showIncomeCategory"),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // 账户类别
              new Picker(
                  adapter: PickerDataAdapter<String>(
                      pickerdata:
                      new JsonDecoder().convert(accountName.toString())),
                  hideHeader: false,
                  onConfirm: (Picker picker, List value) {
                    setState(() {
                      showIncomeAccount = picker.adapter.text;
                      incomeAccountId = accountIndex[picker.adapter.getSelectedValues()[0]];
                    });
                  }).showModal(this.context);
            },
            child: Text("账户：$showIncomeAccount"),
          ),
          // 手势检测器
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            // 当单击时
            onTap: () {
              // 日期时间选择器
              DatePicker.showDateTimePicker(context, showTitleActions: true,
                  onConfirm: (date) {
                    setState(() {
                      whenTime = date;
                    });
                  },
                  // 当前时间
                  currentTime: whenTime,
                  // 语言
                  locale: LocaleType.zh);
            },
            child: Text(
                "时间：${whenTime.year.toString()}-${whenTime.month.toString()
                    .padLeft(2, '0')}-${whenTime.day.toString().padLeft(
                    2, '0')} ${whenTime.hour.toString().padLeft(
                    2, '0')}:${whenTime.minute.toString().padLeft(2, '0')}"),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("备注："),
              Container(
                width: 150,
                child: TextField(
                  keyboardType: TextInputType.number,
                  // 通过controller可以调用用户输入的数据
                  controller: _incomeCommentController,
                ),
              ),
            ],
          ),
          FlatButton(
              child: Text("添加"),
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
              onPressed: () async {
                Global.db.beginTransaction();
                try {
                  if(_incomeAmountController.text.length == 0 ){
                    throw "need amount";
                  }
                  await Global.db.execSQL(
                      'INSERT INTO account_book(types_id,flow,detailed,account_info_id,comment,when_time) values (?,?,?,?,?,?)',
                      [
                        consumeCategoryId,
                        "income",
                        _incomeAmountController.text,
                        incomeAccountId,
                        _incomeCommentController.text,
                        whenTime.toString()
                      ]);
                  if(accountType[incomeAccountId] == 'asset'){
                    await Global.db.execSQL(
                        "UPDATE account_info set amount = amount + ? where id = ?",
                        [
                          _incomeAmountController.text,
                          incomeAccountId
                        ]);
                  }else{
                    await Global.db.execSQL(
                        "UPDATE account_info set amount = amount - ? where id = ?",
                        [
                          _incomeAmountController.text,
                          incomeAccountId
                        ]);
                  }
                  await Global.db.setTransactionSuccessful();
                  _incomeAmountController.clear();
                  _incomeCommentController.clear();
                } catch (e) {
                  showDialog(
                      context: context,
                      builder: (context) =>
                          AlertDialog(
                            content: Text("请检查输入"),));
                } finally {
                  await Global.db.endTransaction();
                }
              }
          ),
        ],
      ),
    );
  }

  // 转账
  Widget transfer() {
    return Center(
      // todo 将其抽离为组件
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("金额："),
              Container(
                width: 100,
                child: TextField(
                  //只允许输入小数
                  inputFormatters: [
                    WhitelistingTextInputFormatter(RegExp("[0-9.]")),
                  ],
                  keyboardType: TextInputType.number,
                  // 通过controller可以调用用户输入的数据
                  controller: _transferAmountController,
                ),
              ),
            ],
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // 转出账户类别
              new Picker(
                  adapter: PickerDataAdapter<String>(
                      pickerdata:
                      new JsonDecoder().convert(accountName.toString())),
                  hideHeader: false,
                  onConfirm: (Picker picker, List value) {
                    setState(() {
                      showTransferAccount = picker.adapter.text;
                      transferAccountId = accountIndex[picker.adapter.getSelectedValues()[0]];
                    });
                  }).showModal(this.context);
            },
            child: Text("转出账户：$showTransferAccount"),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // 转入账户类别
              new Picker(
                  adapter: PickerDataAdapter<String>(
                      pickerdata:
                      new JsonDecoder().convert(accountName.toString())),
                  hideHeader: false,
                  onConfirm: (Picker picker, List value) {
                    setState(() {
                      showTransferAimAccount = picker.adapter.text;
                      transferAimAccountId = accountIndex[picker.adapter.getSelectedValues()[0]];
                    });
                  }).showModal(this.context);
            },
            child: Text("转入账户：$showTransferAimAccount"),
          ),
          // 手势检测器
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            // 当单击时
            onTap: () {
              // 日期时间选择器
              DatePicker.showDateTimePicker(context, showTitleActions: true,
                  onConfirm: (date) {
                    setState(() {
                      whenTime = date;
                    });
                  },
                  // 当前时间
                  currentTime: whenTime,
                  // 语言
                  locale: LocaleType.zh);
            },
            child: Text(
                "时间：${whenTime.year.toString()}-${whenTime.month.toString()
                    .padLeft(2, '0')}-${whenTime.day.toString().padLeft(
                    2, '0')} ${whenTime.hour.toString().padLeft(
                    2, '0')}:${whenTime.minute.toString().padLeft(2, '0')}"),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("备注："),
              Container(
                width: 150,
                child: TextField(
                  keyboardType: TextInputType.number,
                  // 通过controller可以调用用户输入的数据
                  controller: _transferCommentController,
                ),
              ),
            ],
          ),
          FlatButton(
              child: Text("添加"),
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
              onPressed: () async {
                Global.db.beginTransaction();
                try {
                  if(_transferAmountController.text.length == 0 ){
                    throw "need amount";
                  }
                  await Global.db.execSQL(
                      'INSERT INTO account_book(flow,detailed,account_info_id,aim_account_id,comment,when_time) values (?,?,?,?,?,?)',
                      [
                        "transfer",
                        _transferAmountController.text,
                        transferAccountId,
                        transferAimAccountId,
                        _incomeCommentController.text,
                        whenTime.toString()
                      ]);
                  if(accountType[transferAccountId] == accountType[transferAimAccountId]){
                    await Global.db.execSQL(
                        "UPDATE account_info set amount = amount - ? where id = ?",
                        [
                          _transferAmountController.text,
                          transferAccountId
                        ]);
                    await Global.db.execSQL(
                        "UPDATE account_info set amount = amount - ? where id = ?",
                        [
                          _transferAmountController.text,
                          transferAimAccountId
                        ]);
                  }else if(accountType[transferAccountId] == 'asset'){
                    await Global.db.execSQL(
                        "UPDATE account_info set amount = amount - ? where id = ?",
                        [
                          _transferAmountController.text,
                          transferAccountId
                        ]);
                    await Global.db.execSQL(
                        "UPDATE account_info set amount = amount - ? where id = ?",
                        [
                          _transferAmountController.text,
                          transferAimAccountId
                        ]);
                  }else if(accountType[transferAccountId] == 'debt'){
                    await Global.db.execSQL(
                        "UPDATE account_info set amount = amount + ? where id = ?",
                        [
                          _transferAmountController.text,
                          transferAccountId
                        ]);
                    await Global.db.execSQL(
                        "UPDATE account_info set amount = amount + ? where id = ?",
                        [
                          _transferAmountController.text,
                          transferAimAccountId
                        ]);
                  }
                  await Global.db.setTransactionSuccessful();
                  _transferAmountController.clear();
                  _transferCommentController.clear();
                } catch(e){
                  showDialog(
                      context: context,
                      builder: (context) =>
                          AlertDialog(
                            content: Text("请检查输入"),));
                }finally {
                  await Global.db.endTransaction();
                }
              }
          ),
        ],
      ),
    );
  }

// 将支出，收入，转账页面添加到一个list
  listPages() {
    List<Widget> tabPages = new List();
    return tabPages..add(consume())..add(income())..add(transfer());
  }

// 返回页面
  Widget getTabBarPages() {
    return TabBarView(
      children: listPages(),
    );
  }
}
