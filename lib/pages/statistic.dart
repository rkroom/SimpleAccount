import 'package:flutter/material.dart';
import 'package:simple_account/tools/db.dart';

class StatisticWidget extends StatefulWidget {
  const StatisticWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return StatisticWidgetState();
  }
}

class StatisticWidgetState extends State<StatisticWidget> {
  List<Map<String, String>> data = [];

  @override
  void initState() {
    super.initState();
    DB().getMonthlyTransactions().then((value) {
      if (value.isEmpty) {
        return;
      }
      data = [];
      for (var item in value) {
        data.add({'日期': item['date'], '支出': item['amount'].toString()});
      }
      setState(() {
        data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本月支出'),
      ),
      body: data.isEmpty
          ? const Center(child: Text('暂无记录'))
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: TableWidget(
                data: data,
              ),
            ),
    );
  }
}

class TableWidget extends StatelessWidget {
  final List<Map<String, String>> data;
  const TableWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final headers = data[0].keys.toList();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Table(
        border: TableBorder.all(),
        columnWidths: const {
          0: FlexColumnWidth(),
          1: FlexColumnWidth(),
        },
        children: [
          // Header Row
          TableRow(
            children: headers.map((header) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    header,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ),
          // Data Rows
          ...data.map((row) {
            return TableRow(
              children: headers.map((header) {
                return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(row[header] ?? ''),
                    ));
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}
