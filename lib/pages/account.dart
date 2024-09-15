import 'dart:math';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:fl_chart/fl_chart.dart';

import '../tools/config_enum.dart';
import '../tools/db.dart';
import '../tools/tools.dart';

class AccountWidget extends StatefulWidget {
  const AccountWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return AccountWidgetState();
  }
}

class AccountWidgetState extends State<AccountWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 标签
  final tabs = ["统计", "账户"];

  static const _pageSize = 15;
  final TextEditingController _newAccountNameController =
      TextEditingController();

  Map<String, dynamic>? selectedData; // Store the selected item

  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  double totalAssets = 0;
  double totalDebts = 0;
  double currentlyMonthConsume = 0;
  double currentlyMonthIncome = 0;
  double previousMonthConsume = 0;
  double previousMonthIncome = 0;
  double currentlyMonthSummed = 0;
  double previousDayConsume = 0;
  double currentlyDayConsume = 0;

  List<PieChartSectionData> pieChartSections = [];
  List<Map> colorAndName = [];

  void getStatistics() {
    DB().totalBalance('asset').then((value) {
      totalAssets = checkDBresult(value[0]["balance"]);
      setState(() {});
    });

    DB().totalBalance('debt').then((value) {
      totalDebts = checkDBresult(value[0]["balance"]);
      setState(() {});
    });

    var cmd = currentlyMonthDays();
    DB()
        .timeStatistics(Transaction.consume.value, cmd[0], cmd[1])
        .then((value) {
      setState(() {
        currentlyMonthConsume = checkDBresult(value[0]["amount"]);
      });
    });
    DB().timeStatistics(Transaction.income.value, cmd[0], cmd[1]).then((value) {
      setState(() {
        currentlyMonthIncome = checkDBresult(value[0]["amount"]);
      });
    });
    var pmd = previousMonthDays();
    DB()
        .timeStatistics(Transaction.consume.value, pmd[0], pmd[1])
        .then((value) {
      setState(() {
        previousMonthConsume = checkDBresult(value[0]["amount"]);
      });
    });
    DB().timeStatistics(Transaction.income.value, pmd[0], pmd[1]).then((value) {
      setState(() {
        previousMonthIncome = checkDBresult(value[0]["amount"]);
      });
    });
    var today = getTodayRange();
    DB()
        .timeStatistics(Transaction.consume.value, today[0], today[1])
        .then((value) {
      setState(() {
        currentlyDayConsume = checkDBresult(value[0]["amount"]);
      });
    });
    var previousDay = getPreviousDayRange();
    DB()
        .timeStatistics(
            Transaction.consume.value, previousDay[0], previousDay[1])
        .then((value) {
      setState(() {
        previousDayConsume = checkDBresult(value[0]["amount"]);
      });
    });
  }

  Color getRandomColor() {
    Random random = Random();
    return Color.fromARGB(
        100, random.nextInt(256), random.nextInt(256), random.nextInt(256));
  }

  // 转换为字符串并去除尾随零
  String formatNumber(double number) {
    // 尝试将 number 转换为 int
    if (number == number.toInt()) {
      // 如果没有小数部分，转为 int
      return number.toInt().toString();
    } else {
      // 如果有小数部分，保持原样
      return number.toString();
    }
  }

  void getFirstLevelConsume() {
    var cmd = currentlyMonthDays();
    DB().getFirstLevelConsumeAnalysis(cmd[0], cmd[1]).then((value) {
      double total = 0;

      for (var e in value) {
        total = total + e['value'];
      }
      var initialOffset = 0.2;
      for (var e in value) {
        Color color = getRandomColor();
        colorAndName.add({
          "color": color,
          "name":
              //"${e["name"]}(${((e["value"] / total) * 100).toStringAsFixed(2)}%)",
              "${e["name"]}\n${formatNumber(e["value"])}",
          "amount": e["value"],
        });
        var percent = (e["value"] / total);
        var offset = 0.8;
        if (percent <= 0.02) {
          offset = initialOffset;
          if (initialOffset <= 0.9) {
            initialOffset = initialOffset + 0.35;
          }
        }
        pieChartSections.add(PieChartSectionData(
          color: color,
          value: e["value"],
          title: "${(percent * 100).toStringAsFixed(2)}%",
          titlePositionPercentageOffset: offset,
          radius: 120,
        ));
      }
      colorAndName.sort((a, b) => b['amount'].compareTo(a['amount']));
      setState(() {
        pieChartSections;
        colorAndName;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    getStatistics();
    getFirstLevelConsume();
  }

  // 将支出，收入，转账页面添加到一个list
  listPages() {
    List<Widget> tabPages = [];
    return tabPages
      ..add(statistics())
      ..add(account());
  }

// 返回页面
  Widget getTabBarPages() {
    return TabBarView(
      children: listPages(),
    );
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final offset = pageKey * _pageSize;
      //final billDetails = await DB().getAccountInfo(_pageSize, offset);
      final accountInfo = await _databaseHelper.fetchData(_pageSize, offset);
      final isLastPage = accountInfo.isEmpty;
      if (isLastPage) {
        _pagingController.appendLastPage(accountInfo);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(accountInfo, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void onItemPressed(Map<String, dynamic> item) {
    setState(() {
      if (selectedData == item) {
        selectedData = null;
      } else {
        selectedData = item;
      }
    });
  }

  Future<void> _showConfirmationDialog(Map<String, dynamic> item, index) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${item['name']}'),
          content: SizedBox(
            //设置高度
            height: 100,
            child: Column(
              children: [
                const Text('是否修改账户名称 ?'),
                TextField(
                  controller: _newAccountNameController,
                  decoration: const InputDecoration(labelText: '输入新名称'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (_newAccountNameController.text.isEmpty) {
                  showNoticeSnackBar(context, "账户名不能为空");
                  return;
                }
                final List<Map<String, dynamic>> currentItems =
                    List.from(_pagingController.itemList ?? []);
                var tempAccountINfo = Map.of(currentItems[index]);
                tempAccountINfo['name'] = _newAccountNameController.text;
                DB().updateAccountName(
                    _newAccountNameController.text, item['id']);
                currentItems[index] = tempAccountINfo;
                _pagingController.itemList = currentItems;
                _newAccountNameController.clear();
                //_pagingController.refresh();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
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

  Widget account() {
    return Scaffold(
      body: PagedListView<int, Map<String, dynamic>>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
          itemBuilder: (context, item, index) {
            return Column(
              children: [
                ListTile(
                  title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(child: Text(item['name'])),
                        Expanded(child: Text(item['type'])),
                        Expanded(child: Text(item['balance'].toString()))
                      ]),
                  //subtitle: Text('ID: ${item['id']}'),
                  onTap: () {
                    onItemPressed(item);
                  },
                ),
                if (selectedData == item)
                  ElevatedButton(
                    onPressed: () {
                      _showConfirmationDialog(item, index);
                    },
                    child: const Text('修改账户名'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget statistics() {
    double deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Wrap(
              spacing: 5.0, // 水平方向的间距
              runSpacing: 2.0, // 垂直方向的间距
              children: [
                if (totalAssets != 0.0) Text("总资产： $totalAssets"),
                if (totalDebts != 0.0) Text("总负债： ${0 - totalDebts}"),
                if ((totalAssets + totalDebts) != 0.0)
                  Text("净资产： ${(totalAssets + totalDebts).toStringAsFixed(2)}"),
                if (previousMonthConsume != 0.0)
                  Text("上月支出： $previousMonthConsume"),
                if (previousMonthIncome != 0.0)
                  Text("上月收支： $previousMonthIncome"),
                if (currentlyMonthConsume != 0.0)
                  Text("本月支出： $currentlyMonthConsume"),
                if (currentlyMonthIncome != 0.0)
                  Text("本月收入： $currentlyMonthIncome"),
                if ((currentlyMonthIncome - currentlyMonthConsume) != 0.0)
                  Text(
                      "本月总计： ${(currentlyMonthIncome - currentlyMonthConsume).toStringAsFixed(2)}"),
                if (previousDayConsume != 0.0)
                  Text("昨日支出： $previousDayConsume"),
                if (currentlyDayConsume != 0.0)
                  Text("今日支出： $currentlyDayConsume"),
              ]),
          SizedBox(
            height: deviceHeight*0.37,
            child: PieChart(
                PieChartData(centerSpaceRadius: 0, sections: pieChartSections)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: GridView.count(
                crossAxisCount: 3, // 每行的按钮数量，可以调整为你需要的数量
                crossAxisSpacing: 8.0, // 横向间距
                mainAxisSpacing: 8.0, // 纵向间距
                childAspectRatio: 2.5, // 宽高比
                children: List.generate(colorAndName.length, (index) {
                  return Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(1.0),
                    decoration: BoxDecoration(
                      color: colorAndName[index]["color"],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      colorAndName[index]["name"], // 显示标签文本
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}

class DatabaseHelper {
  Future<List<Map<String, dynamic>>> fetchData(int limit, int offset) async {
    return await DB().getAccountInfo(limit, offset);
  }
}
