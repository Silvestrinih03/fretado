import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<int> driverOfferRefreshSignal = ValueNotifier<int>(0);

void requestDriverOfferRefresh() {
  driverOfferRefreshSignal.value++;
}

void redirectToLogin() {
  final NavigatorState? navigator = appNavigatorKey.currentState;
  if (navigator == null) return;

  navigator.pushNamedAndRemoveUntil('/', (route) => false);
}
