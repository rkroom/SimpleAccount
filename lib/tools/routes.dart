import 'package:flutter/material.dart';
import 'package:simple_account/pages/bill_listener.dart';

import '../pages/home.dart';
import '../pages/loading.dart';
import '../pages/manage.dart';
import 'config.dart';


final Map<String, Function> routes = {
  '/' : (context) =>   Global.jumpLoad?const BottomNavigationWidget():const LoadingWidget(),
  '/home': (context) => const BottomNavigationWidget(),
  '/createdb': (context) => const CreateDatabaseWidget(),
  // arguments传递参数
  '/selectdb': (context, {arguments}) =>
      SelectDatabaseWidget(arguments: arguments),
  '/manage': (context) => const ManageWidget(),
  '/accountFile': (context) => const LoadingWidget(),
  '/billListener': (context) => const BillListenerWidget(),
};

Route<dynamic>? onGenerateRoute(settings) {
  // 统一处理
  final String name = settings.name;
  final Function? pageContentBuilder = routes[name];
  if (pageContentBuilder != null) {
    if (settings.arguments != null) {
      final Route route = MaterialPageRoute(
          builder: (context) =>
              pageContentBuilder(context, arguments: settings.arguments));
      return route;
    } else {
      final Route route =
          MaterialPageRoute(builder: (context) => pageContentBuilder(context));
      return route;
    }
  }
  return null;
}
