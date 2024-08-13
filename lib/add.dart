import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:simple_account/db.dart';
import 'package:simple_account/event_bus.dart';
import 'package:simple_account/tools.dart';

class AddWidget extends StatefulWidget {
  const AddWidget({super.key});
  @override
  State<StatefulWidget> createState() {
    return AddWidgetState();
  }
}

class AddWidgetState extends State<AddWidget>
    with AutomaticKeepAliveClientMixin {
  static const TextScaler customTextScaler = TextScaler.linear(1.2);

  @override
  bool get wantKeepAlive => true;

  // 标签
  final tabs = ["支出", "收入", "转账"];

  // 记录时间
  DateTime whenTime = DateTime.now();
  // 支出功能变量
  List consumeCategory = [];
  List<int>? selectedConsumeCategory;
  String showConsumeCategory = "请选择";
  Map consumeCategoryIndex = {};
  late int consumeCategoryId;
  final TextEditingController _consumeAmountController =
      TextEditingController();
  final TextEditingController _consumeCommentController =
      TextEditingController();
  // 收入功能变量
  List incomeCategory = [];
  List<int>? selectedIncomeCategory;
  String showIncomeCategory = "请选择";
  Map incomeCategoryIndex = {};
  late int incomeCategoryId;
  final TextEditingController _incomeAmountController = TextEditingController();
  final TextEditingController _incomeCommentController =
      TextEditingController();
  // 转账功能变量
  String showConsumeAccount = "请选择";
  late int consumeAccountId;
  String showIncomeAccount = "请选择";
  late int incomeAccountId;
  String showTransferAccount = "请选择";
  late int transferAccountId;
  String showTransferAimAccount = "请选择";
  late int transferAimAccountId;
  final TextEditingController _transferAmountController =
      TextEditingController();
  final TextEditingController _transferCommentController =
      TextEditingController();
  // 账户信息功能
  List accountName = [];
  Map accountIndex = {};
  Map accountType = {};

  List<Map<String, dynamic>> dataArray = [];
  List<Map<String, dynamic>> accountArray = [];

// 获取分类
  Future getCategory(String flow) async {
    /*
    查询数据库，并将结果转换为LIST，采用遍历将其转换LIST<MAP>形式的结构
     */
    // 查询数据库，并将结果转换为LIST
    List list = (await DB().getCategorys(flow)).toList();
    // category与对应Id的MAP
    Map categoryIndex = {};

    Map<String, List<String>> categoryMap = {};
    // 遍历结果
    for (var l in list) {
      String specificCategory = l['specific_category']!;
      String name = l['name']!;
      if (!categoryMap.containsKey(name)) {
        categoryMap[name] = [];
      }
      categoryMap[name]!.add(specificCategory);
      categoryIndex[l["specific_category"]] = l["id"];
    }
    //分类List
    List<Map<String, List<String>>> category = categoryMap.entries.map((entry) {
      return {entry.key: entry.value};
    }).toList();
    // LIST，包含分类和分类的ID
    return [category, categoryIndex];
  }

// 获取账户信息
  Future getAccount() async {
    List list = (await DB().getAccounts()).toList();
    List accountName = [];
    Map accountIndex = {};
    Map accountType = {};
    for (var l in list) {
      accountName.add(l["name"]);
      accountIndex[l["name"]] = l["id"];
      accountType[l["id"]] = l["type"];
    }
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

    DB().getMostFrequentType("consume").then((v) {
      setState(() {
        dataArray = v;
      });
    });

    DB().getMostFrequentAccount("consume").then((v) {
      setState(() {
        accountArray = v;
      });
    });

    bus.on("update_category", (arg) {
      getCategory("consume").then((list) {
        consumeCategory = list[0];
        consumeCategoryIndex = list[1];
      });
      // 初始化收入分类信息
      getCategory("income").then((list) {
        incomeCategory = list[0];
        incomeCategoryIndex = list[1];
      });
      setState(() {});
    });

    bus.on("update_account", (arg) {
      getAccount().then((list) {
        accountName = list[0];
        accountIndex = list[1];
        accountType = list[2];
      });
      setState(() {});
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
          preferredSize: const Size.fromHeight(kToolbarHeight),
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
    return Column(
      children: [
        Expanded(
          child: GridView.count(
            crossAxisCount: 3, // 每行的按钮数量，可以调整为你需要的数量
            crossAxisSpacing: 8.0, // 横向间距
            mainAxisSpacing: 8.0, // 纵向间距
            childAspectRatio: 2, // 宽高比
            children: dataArray.map((item) {
              return Container(
                margin: const EdgeInsets.all(8.0), // 添加间距
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedConsumeCategory =
                          findElementIndexes(consumeCategory, item['category']);
                      showConsumeCategory = item['category'];
                      consumeCategoryId = item['id'];
                    });
                  },
                  child: Text(' ${item['category']}'),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3, // 每行的按钮数量，可以调整为你需要的数量
            crossAxisSpacing: 8.0, // 横向间距
            mainAxisSpacing: 8.0, // 纵向间距
            childAspectRatio: 2, // 宽高比
            children: accountArray.map((item) {
              return Container(
                margin: const EdgeInsets.all(8.0), // 添加间距
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showConsumeAccount = item['name'];
                      consumeAccountId = item['id'];
                    });
                  },
                  child: Text(' ${item['name']}'),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Align(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("金额："),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        //只允许输入小数
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp("[0-9.]")),
                        ],
                        keyboardType: TextInputType.number,
                        // 通过controller可以调用用户输入的数据
                        controller: _consumeAmountController,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: GestureDetector(
                    // 手势
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      //点击事件
                      // 支出类别
                      Picker(
                          // 打开时选择默认选择的分类，其类型为list
                          selecteds: selectedConsumeCategory,
                          // 选择器
                          adapter: PickerDataAdapter<String>(
                              pickerData: consumeCategory),
                          changeToFirst: true,
                          hideHeader: false,
                          confirmText: "确认",
                          cancelText: "取消",
                          // 当点击确认按钮时
                          onConfirm: (Picker picker, List<int> value) {
                            setState(() {
                              // 将默认值修改为本次的选择，下次打开时，其值为本次的选择
                              selectedConsumeCategory = value;
                              // 显示于界面的变量
                              showConsumeCategory = picker.adapter.text;
                              // 设置支出分类的ID
                              consumeCategoryId = consumeCategoryIndex[
                                  picker.getSelectedValues()[1]];
                            });
                          }).showModal(context);
                    },
                    // 界面显示
                    child: Text(
                      "类目：$showConsumeCategory",
                      textScaler: customTextScaler,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      // 账户类别
                      Picker(
                          confirmText: "确认",
                          cancelText: "取消",
                          adapter: PickerDataAdapter<String>(
                              pickerData: accountName),
                          changeToFirst: true,
                          hideHeader: false,
                          onConfirm: (Picker picker, List value) {
                            setState(() {
                              // 显示于界面
                              showConsumeAccount = picker.adapter.text;
                              // 设置支出账户的ID
                              consumeAccountId =
                                  accountIndex[picker.getSelectedValues()[0]];
                            });
                          }).showModal(context);
                    },
                    child: Text(
                      "账户：$showConsumeAccount",
                      textScaler: customTextScaler,
                    ),
                  ),
                ),
                // 手势检测器
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // 当单击时
                    onTap: () {
                      // 日期时间选择器
                      DatePicker.showDateTimePicker(context,
                          showTitleActions: true, onConfirm: (date) {
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
                      "时间：${whenTime.year.toString()}-${whenTime.month.toString().padLeft(2, '0')}-${whenTime.day.toString().padLeft(2, '0')} ${whenTime.hour.toString().padLeft(2, '0')}:${whenTime.minute.toString().padLeft(2, '0')}",
                      textScaler: customTextScaler,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("备注："),
                    // 使用Container包裹，以组装TextField
                    SizedBox(
                      width: 150,
                      child: TextField(
                        // 通过controller可以调用用户输入的数据
                        controller: _consumeCommentController,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                    //按钮
                    child: const Text("添加"),
                    // 点击按钮事件
                    onPressed: () async {
                      if (_consumeAmountController.text.isEmpty) {
                        showNoticeSnackBar(context, "金额不能为空");
                        return;
                      }
                      try {
                        DB().addBill(
                            consumeCategoryId,
                            "consume",
                            _consumeAmountController.text,
                            consumeAccountId,
                            _consumeCommentController.text,
                            whenTime.toString());
                        _consumeAmountController.clear();
                        _consumeCommentController.clear();
                      } catch (error) {
                        //print(error);
                        showNoticeSnackBar(context, "添加失败，请检查输入");
                      }
                    }),
              ],
            ),
          ),
        )
      ],
    );
  }

  //收入
  Widget income() {
    return Stack(
        // todo 将其抽离为组件
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("金额："),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        //只允许输入小数
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp("[0-9.]")),
                        ],
                        keyboardType: TextInputType.number,
                        // 通过controller可以调用用户输入的数据
                        controller: _incomeAmountController,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      // 支出类别
                      Picker(
                          confirmText: "确认",
                          cancelText: "取消",
                          selecteds: selectedIncomeCategory,
                          adapter: PickerDataAdapter<String>(
                              pickerData: incomeCategory),
                          changeToFirst: true,
                          hideHeader: false,
                          onConfirm: (Picker picker, List<int> value) {
                            setState(() {
                              selectedIncomeCategory = value;
                              showIncomeCategory = picker.adapter.text;
                              incomeCategoryId = incomeCategoryIndex[
                                  picker.getSelectedValues()[1]];
                            });
                          }).showModal(context);
                    },
                    child: Text(
                      "类目：$showIncomeCategory",
                      textScaler: customTextScaler,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      // 账户类别
                      Picker(
                          confirmText: "确认",
                          cancelText: "取消",
                          adapter: PickerDataAdapter<String>(
                              pickerData: accountName),
                          hideHeader: false,
                          onConfirm: (Picker picker, List value) {
                            setState(() {
                              showIncomeAccount = picker.adapter.text;
                              incomeAccountId =
                                  accountIndex[picker.getSelectedValues()[0]];
                            });
                          }).showModal(context);
                    },
                    child: Text(
                      "账户：$showIncomeAccount",
                      textScaler: customTextScaler,
                    ),
                  ),
                ),
                // 手势检测器
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // 当单击时
                    onTap: () {
                      // 日期时间选择器
                      DatePicker.showDateTimePicker(context,
                          showTitleActions: true, onConfirm: (date) {
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
                      "时间：${whenTime.year.toString()}-${whenTime.month.toString().padLeft(2, '0')}-${whenTime.day.toString().padLeft(2, '0')} ${whenTime.hour.toString().padLeft(2, '0')}:${whenTime.minute.toString().padLeft(2, '0')}",
                      textScaler: customTextScaler,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("备注："),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        // 通过controller可以调用用户输入的数据
                        controller: _incomeCommentController,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                    child: const Text("添加"),
                    // 点击按钮事件
                    onPressed: () async {
                      if (_incomeAmountController.text.isEmpty) {
                        showNoticeSnackBar(context, "金额不能为空");
                        return;
                      }
                      try {
                        DB().addBill(
                            incomeCategoryId,
                            "income",
                            _incomeAmountController.text,
                            incomeAccountId,
                            _incomeCommentController.text,
                            whenTime.toString());
                        _incomeAmountController.clear();
                        _incomeCommentController.clear();
                      } catch (error) {
                        //print(error);
                        showNoticeSnackBar(context, "添加失败，请检查输入");
                      }
                    }),
              ],
            ),
          ),
        ]);
  }

  // 转账
  Widget transfer() {
    // todo 将其抽离为组件
    return Stack(alignment: Alignment.bottomCenter, children: [
      Positioned(
        bottom: 20,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text("金额："),
                SizedBox(
                  width: 100,
                  child: TextField(
                    //只允许输入小数
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9.]")),
                    ],
                    keyboardType: TextInputType.number,
                    // 通过controller可以调用用户输入的数据
                    controller: _transferAmountController,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // 转出账户类别
                  Picker(
                      confirmText: "确认",
                      cancelText: "取消",
                      adapter:
                          PickerDataAdapter<String>(pickerData: accountName),
                      hideHeader: false,
                      onConfirm: (Picker picker, List value) {
                        setState(() {
                          showTransferAccount = picker.adapter.text;
                          transferAccountId = accountIndex[
                              picker.adapter.getSelectedValues()[0]];
                        });
                      }).showModal(context);
                },
                child: Text(
                  "转出账户：$showTransferAccount",
                  textScaler: customTextScaler,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // 转入账户类别
                  Picker(
                      confirmText: "确认",
                      cancelText: "取消",
                      adapter:
                          PickerDataAdapter<String>(pickerData: accountName),
                      hideHeader: false,
                      onConfirm: (Picker picker, List value) {
                        setState(() {
                          showTransferAimAccount = picker.adapter.text;
                          transferAimAccountId = accountIndex[
                              picker.adapter.getSelectedValues()[0]];
                        });
                      }).showModal(context);
                },
                child: Text(
                  "转入账户：$showTransferAimAccount",
                  textScaler: customTextScaler,
                ),
              ),
            ),
            // 手势检测器
            Padding(
              padding: const EdgeInsets.all(5),
              child: GestureDetector(
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
                  "时间：${whenTime.year.toString()}-${whenTime.month.toString().padLeft(2, '0')}-${whenTime.day.toString().padLeft(2, '0')} ${whenTime.hour.toString().padLeft(2, '0')}:${whenTime.minute.toString().padLeft(2, '0')}",
                  textScaler: customTextScaler,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text("备注："),
                SizedBox(
                  width: 150,
                  child: TextField(
                    // 通过controller可以调用用户输入的数据
                    controller: _transferCommentController,
                  ),
                ),
              ],
            ),
            ElevatedButton(
                child: const Text("添加"),
                // 点击按钮事件
                onPressed: () async {
                  if (_transferAmountController.text.isEmpty) {
                    showNoticeSnackBar(context, "金额不能为空");
                    return;
                  }
                  try {
                    DB().addTransfer(
                        _transferAmountController.text,
                        transferAccountId,
                        transferAimAccountId,
                        _transferCommentController.text,
                        whenTime.toString());
                    _transferAmountController.clear();
                    _transferCommentController.clear();
                  } catch (error) {
                    //print(error);
                    showNoticeSnackBar(context, "添加失败，请检查输入");
                  }
                }),
          ],
        ),
      ),
    ]);
  }

// 将支出，收入，转账页面添加到一个list
  listPages() {
    List<Widget> tabPages = [];
    return tabPages
      ..add(consume())
      ..add(income())
      ..add(transfer());
  }

// 返回页面
  Widget getTabBarPages() {
    return TabBarView(
      children: listPages(),
    );
  }
}
