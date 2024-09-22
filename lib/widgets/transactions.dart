import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_picker_plus/picker.dart';

import '../tools/db.dart';
import '../tools/tools.dart';
import '../tools/config_enum.dart';

class Transactions extends StatefulWidget {
  final String? amount;
  final Transaction flow;
  final List accountNames;
  final Map accountIndexs;
  final List<int>? selectedCategory;
  final Map categoryIndex;
  final List categories;
  final DateTime time;
  final String accountText;
  final int? accountId;
  final String categoryText;
  final int? categoryId;
  final void Function(bool success)? addSuccess;
  final void Function(String value)? onAmountChanged;
  final void Function(Map category)? onCategoryConfirm;
  final void Function(Map account)? onAccountConfirm;
  final void Function(DateTime time)? onTimeChanged;

  const Transactions({
    super.key,
    this.amount,
    required this.flow,
    required this.accountNames,
    required this.accountIndexs,
    this.selectedCategory,
    required this.categoryIndex,
    required this.categories,
    required this.time,
    required this.accountText,
    required this.accountId,
    required this.categoryText,
    required this.categoryId,
    this.addSuccess,
    this.onAmountChanged,
    this.onCategoryConfirm,
    this.onAccountConfirm,
    this.onTimeChanged,
  });

  @override
  State<StatefulWidget> createState() {
    return TransactionsState();
  }
}

class TransactionsState extends State<Transactions> {
  static const TextScaler customTextScaler = TextScaler.linear(1.2);

  late TextEditingController _amountController;
  // 账户信息
  late List accountName;
  late Map accountIndex;
  late Map accountType;
  List<int>? selectedCategory;
  late List category;
  late DateTime whenTime;
  late String showAccount;

  late String showCategory;
  late int categoryId;
  late int accountId;
  late Map categoryIndex;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.amount);
    accountName = widget.accountNames;
    accountIndex = widget.accountIndexs;
    selectedCategory = widget.selectedCategory;
    categoryIndex = widget.categoryIndex;
    category = widget.categories;
    whenTime = widget.time;
    showAccount = widget.accountText;
    if (widget.accountId != null) {
      accountId = widget.accountId!;
    }
    showCategory = widget.categoryText;
    if (widget.categoryId != null) {
      categoryId = widget.categoryId!;
    }
  }

  @override
  void didUpdateWidget(covariant Transactions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountText != widget.accountText) {
      showAccount = widget.accountText; // 更新文本内容
    }
    if (oldWidget.accountId != widget.accountId) {
      accountId = widget.accountId!;
    }
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      selectedCategory = widget.selectedCategory;
    }
    if (oldWidget.categoryText != widget.categoryText) {
      showCategory = widget.categoryText;
    }
    if (oldWidget.categoryId != widget.categoryId) {
      categoryId = widget.categoryId!;
    }
    if (oldWidget.categories != widget.categories) {
      category = widget.categories;
    }
    if (oldWidget.categoryIndex != widget.categoryIndex) {
      categoryIndex = widget.categoryIndex;
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
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        // 通过controller可以调用用户输入的数据
                        controller: _amountController,
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
                          selecteds: selectedCategory,
                          // 选择器
                          adapter:
                              PickerDataAdapter<String>(pickerData: category),
                          changeToFirst: true,
                          hideHeader: false,
                          confirmText: "确认",
                          cancelText: "取消",
                          // 当点击确认按钮时
                          onConfirm: (Picker picker, List<int> value) {
                            setState(() {
                              // 将默认值修改为本次的选择，下次打开时，其值为本次的选择
                              selectedCategory = value;
                              // 显示于界面的变量
                              showCategory = picker.adapter.text;
                              // 设置支出分类的ID
                              categoryId =
                                  categoryIndex[picker.getSelectedValues()[1]];
                            });
                            widget.onCategoryConfirm?.call({
                              "selected": value,
                              "text": picker.adapter.text,
                              "categoryId":
                                  categoryIndex[picker.getSelectedValues()[1]]
                            });
                          }).showModal(context);
                    },
                    // 界面显示
                    child: Text(
                      "类目：$showCategory",
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
                              showAccount = picker.adapter.text;
                              // 设置支出账户的ID
                              accountId =
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
                      "账户：$showAccount",
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
                        controller: _commentController,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                    //按钮
                    child: const Text("添加"),
                    // 点击按钮事件
                    onPressed: () async {
                      if (_amountController.text.isEmpty) {
                        showNoticeSnackBar(context, "金额不能为空");
                        widget.addSuccess?.call(false);
                        return;
                      }
                      try {
                        DB().addBill(
                            categoryId,
                            widget.flow.value,
                            _amountController.text,
                            accountId,
                            _commentController.text,
                            whenTime.toString());
                        _amountController.clear();
                        _commentController.clear();
                        //FocusScope.of(context).unfocus();
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
