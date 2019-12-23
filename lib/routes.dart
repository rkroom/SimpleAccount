import 'package:flutter/material.dart';
import 'loading.dart';
import 'home.dart';

final Map<String, Function> routes = {
  '/' : (context) => new LoadingWidget(),
  '/home' : (context) => new BottomNavigationWidget(),
};



Route<dynamic> onGenerateRoute(settings) {
  // 统一处理
  final String name = settings.name;
  final Function pageContentBuilder = routes[name];
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
