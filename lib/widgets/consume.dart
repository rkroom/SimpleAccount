import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_picker_plus/picker.dart';

import '../tools/db.dart';
import '../tools/tools.dart';

class Consume extends StatefulWidget {
  final String? amount;
  final List accountNames;
  final Map accountIndexs;
  final Map accountTypes;
  final List<int>? selectedCategory;
  final Map categoryIndex;
  final List consumeCategories;
  final DateTime time;
  final String consumeAccountText;
  final int? accountId;
  final String consumeCategoryText;
  final int? categoryId;
  final void Function(bool success)? addSuccess;
  final void Function(String value)? onAmountChanged;
  final void Function(Map category)? onCategoryConfirm;
  final void Function(Map account)? onAccountConfirm;
  final void Function(DateTime time)? onTimeChanged;

  const Consume({
    super.key,
    this.amount,
    required this.accountNames,
    required this.accountIndexs,
    required this.accountTypes,
    this.selectedCategory,
    required this.categoryIndex,
    required this.consumeCategories,
    required this.time,
    required this.consumeAccountText,
    required this.accountId,
    required this.consumeCategoryText,
    required this.categoryId,
    this.addSuccess,
    this.onAmountChanged,
    this.onCategoryConfirm,
    this.onAccountConfirm,
    this.onTimeChanged,
  });

  @override
  State<StatefulWidget> createState() {
    return ConsumeState();
  }
}

class ConsumeState extends State<Consume> {
  static const TextScaler customTextScaler = TextScaler.linear(1.2);

  late TextEditingController _consumeAmountController;
  // 账户信息
  late List accountName;
  late Map accountIndex;
  late Map accountType;
  List<int>? selectedConsumeCategory;
  late List consumeCategory;
  late DateTime whenTime;
  late String showConsumeAccount;

  late String showConsumeCategory;
  late int consumeCategoryId;
  late int consumeAccountId;
  late Map consumeCategoryIndex;
  final TextEditingController _consumeCommentController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _consumeAmountController = TextEditingController(text: widget.amount);
    accountName = widget.accountNames;
    accountIndex = widget.accountIndexs;
    accountType = widget.accountTypes;
    selectedConsumeCategory = widget.selectedCategory;
    consumeCategoryIndex = widget.categoryIndex;
    consumeCategory = widget.consumeCategories;
    whenTime = widget.time;
    showConsumeAccount = widget.consumeAccountText;
    if (widget.accountId != null) {
      consumeAccountId = widget.accountId!;
    }
    showConsumeCategory = widget.consumeCategoryText;
    if (widget.categoryId != null) {
      consumeCategoryId = widget.categoryId!;
    }
  }

  @override
  void didUpdateWidget(covariant Consume oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.consumeAccountText != widget.consumeAccountText) {
      showConsumeAccount = widget.consumeAccountText; // 更新文本内容
    }
    if (oldWidget.accountId != widget.accountId) {
      consumeAccountId = widget.accountId!;
    }
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      selectedConsumeCategory = widget.selectedCategory;
    }
    if (oldWidget.consumeCategoryText != widget.consumeCategoryText) {
      showConsumeCategory = widget.consumeCategoryText;
    }
    if (oldWidget.categoryId != widget.categoryId) {
      consumeCategoryId = widget.categoryId!;
    }
    if (oldWidget.consumeCategories != widget.consumeCategories) {
      consumeCategory = widget.consumeCategories;
    }
    if (oldWidget.categoryIndex != widget.categoryIndex) {
      consumeCategoryIndex = widget.categoryIndex;
    }
    if (oldWidget.accountNames != widget.accountNames) {
      accountName = widget.accountNames;
    }
    if (oldWidget.accountIndexs != widget.accountIndexs) {
      accountIndex = widget.accountIndexs;
    }
    if (oldWidget.time != widget.time) {
      whenTime = widget.time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                        onChanged: (value) =>
                            {widget.onAmountChanged?.call(value)},
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
                            widget.onCategoryConfirm?.call({
                              "selected": value,
                              "text": picker.adapter.text,
                              "categoryId": consumeCategoryIndex[
                                  picker.getSelectedValues()[1]]
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
                            widget.onAccountConfirm?.call({
                              "text": picker.adapter.text,
                              "accountId":
                                  accountIndex[picker.getSelectedValues()[0]]
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
                        widget.onTimeChanged?.call(date);
                      },
                          // 打开时显示的时间
                          currentTime: whenTime,
                          // 语言
                          locale: LocaleType.zh);
                    },
                    child: Text(
                      ""
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
                        widget.addSuccess?.call(false);
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
                        widget.addSuccess?.call(true);
                      } catch (error) {
                        debugPrint(error.toString());
                        showNoticeSnackBar(context, "添加失败，请检查输入");
                        widget.addSuccess?.call(false);
                      }
                    }),
              ],
            ),
          ),
        )
      ],
    );
  }
}
