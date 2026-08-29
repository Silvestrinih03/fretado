import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void redirectToLogin() {
  final NavigatorState? navigator = appNavigatorKey.currentState;
  if (navigator == null) return;

  navigator.pushNamedAndRemoveUntil('/', (route) => false);
}
