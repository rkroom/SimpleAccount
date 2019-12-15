import 'package:flutter/material.dart';

class StatementWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return new StatementWidgetState();
  }
}

class StatementWidgetState extends State<StatementWidget>{
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('账单'),
      ),
      body: new Center(
        child: Icon(Icons.receipt,size: 130.0,color: Colors.blue,),
      ),
    );
  }
}