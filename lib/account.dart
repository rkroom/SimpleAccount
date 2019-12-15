import 'package:flutter/material.dart';

class AccountWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return new AccountWidgetState();
  }
}

class AccountWidgetState extends State<AccountWidget>{
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('账户'),
      ),
      body: new Center(
        child: Icon(Icons.local_atm,size: 130.0,color: Colors.blue,),
      ),
    );
  }
}