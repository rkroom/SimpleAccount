import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:simple_account/db.dart';
import 'package:simple_account/tools.dart';
import 'package:fl_chart/fl_chart.dart';

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
  final tabs = ["账户", "统计"];

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

  List<PieChartSectionData> pieChartSections = [];

  double checkDBresult(value) {
    if (value == null) {
      return 0;
    }
    if (value.isNaN) {
      return 0;
    }
    return value;
  }

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
    DB().timeStatistics('consume', cmd[0], cmd[1]).then((value) {
      currentlyMonthConsume = checkDBresult(value[0]["amount"]);
      setState(() {});
    });
    DB().timeStatistics('income', cmd[0], cmd[1]).then((value) {
      currentlyMonthIncome = checkDBresult(value[0]["amount"]);
      setState(() {});
    });
    var pmd = previousMonthDays();
    DB().timeStatistics('consume', pmd[0], pmd[1]).then((value) {
      previousMonthConsume = checkDBresult(value[0]["amount"]);
      setState(() {});
    });
    DB().timeStatistics('income', pmd[0], pmd[1]).then((value) {
      previousMonthIncome = checkDBresult(value[0]["amount"]);
      setState(() {});
    });
  }

  void getFirstLevelConsume() {
    var cmd = currentlyMonthDays();
    DB().getFirstLevelConsumeAnalysis(cmd[0], cmd[1]).then((value) {
      double total = 0;
      for (var e in value) {
        total = total + e['value'];
      }
      for (var e in value) {
        pieChartSections.add(PieChartSectionData(
          value: e["value"],
          title:
              '${e["name"]}\n${e["value"]}(${((e["value"] / total) * 100).toStringAsFixed(2)}%)',
          radius: 120,
        ));
      }
      setState(() {
        pieChartSections;
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
      ..add(account())
      ..add(statistics());
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
          content: Column(
            children: [
              const Text('是否修改账户名称 ?'),
              TextField(
                controller: _newAccountNameController,
                decoration: const InputDecoration(labelText: '输入新名称'),
              ),
            ],
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
                        Expanded(child:Text(item['name'])),
                        Expanded(child:Text(item['type'])),
                        Expanded(child:Text(item['balance'].toString()))
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
    return Scaffold(
      body: Column(
        children: [
          Text("总资产： $totalAssets"),
          Text("总负债： ${0 - totalDebts}"),
          Text("净资产： ${totalAssets + totalDebts}"),
          Text("本月支出： $currentlyMonthConsume"),
          Text("本月收入： $currentlyMonthIncome"),
          Text("本月总计： ${currentlyMonthIncome - currentlyMonthConsume}"),
          Text("上月支出： $previousMonthConsume"),
          Text("上月收入： $previousMonthIncome"),
          SizedBox(
              height: 300,
              child: PieChart(PieChartData(
                  centerSpaceRadius: 0, sections: pieChartSections))),
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
