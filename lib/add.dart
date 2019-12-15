import 'package:flutter/material.dart';

class AddWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return new AddWidgetState();
  }
}

class AddWidgetState extends State<AddWidget>{
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('添加'),
      ),
      body: new Center(
        child: Icon(Icons.plus_one,size: 130.0,color: Colors.blue,),
      ),
    );
  }
}