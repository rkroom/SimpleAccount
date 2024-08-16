import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../tools/db.dart';


class StatementWidget extends StatefulWidget {
  const StatementWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return StatementWidgetState();
  }
}

class StatementWidgetState extends State<StatementWidget> {
  static const _pageSize = 13;

  Map<String, dynamic>? selectedData; // Store the selected item

  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final offset = pageKey * _pageSize;
      //final billDetails = await DB().getBillDetails(_pageSize, offset);
      final billDetails = await _databaseHelper.fetchData(_pageSize, offset);
      final isLastPage = billDetails.isEmpty;
      if (isLastPage) {
        _pagingController.appendLastPage(billDetails);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(billDetails, nextPageKey);
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

  void _showConfirmationDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认'),
          content: Text('是否确认删除金额为: ${item['detailed']} 的账单?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                _pagingController.itemList?.remove(item);
                //_pagingController.refresh();
                _pagingController.itemList =
                    List.from(_pagingController.itemList!);
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
    return Scaffold(
      body: PagedListView<int, Map<String, dynamic>>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
          itemBuilder: (context, item, index) {
            return Container(
              decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(width: 1, color: Color(0xffe5e5e5)))),
              child: Column(
                children: [
                  ListTile(
                    title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(flex: 3, child: Text(item['account'])),
                          Expanded(
                              flex: 2,
                              child: Text(item['detailed'].toString())),
                          Expanded(flex: 2, child: Text(item['flow'])),
                          if (item['aim_account'] != null)
                            Expanded(flex: 3, child: Text(item['aim_account'])),
                          if (item['category'] != null)
                            Expanded(flex: 3, child: Text(item['category']))
                        ]),
                    subtitle: Row(children: [
                      //Container(
                      //  width: 20,
                      //),
                      Row(children: [
                        Text(item['date'].substring(5)),
                        const Text(" "),
                        if (item['comment'] != null && item['comment'] != '')
                          Text('备注: ${item['comment']}'),
                      ])
                    ]),
                    onTap: () {
                      onItemPressed(item);
                    },
                  ),
                  if (selectedData == item)
                    ElevatedButton(
                      onPressed: () {
                        DB().deleteBill(item['id']);
                        _showConfirmationDialog(item);
                      },
                      child: const Text('删除'),
                    ),
                ],
              ),
            );
          },
          noItemsFoundIndicatorBuilder: (context) {
            return const Center(
              child: Text("尚无记录，添加第一笔记录吧！"),
            );
          },
        ),
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
    return await DB().getBillDetails(limit, offset);
  }
}






/*
class BillDetails {
final String dateTime;
final String category;
final String flow;
final double detailed;
final String account;
final String aimAccount;
final String comment;
const BillDetails ({
  required this.dateTime, 
  required this.category, 
  required this.flow, 
  required this.detailed, 
  required this.account, 
  required this.aimAccount, 
  required this.comment, 
});
}*/