import 'package:flutter/material.dart';

import '../../../../core/enums/home_profile.dart';
import '../widgets/client_home_content.dart';
import '../widgets/driver_home_content.dart';
import '../widgets/home_shell.dart';

class HomePage extends StatelessWidget {
  final HomeProfile profile;
  final String userName;

  const HomePage({
    super.key,
    this.profile = HomeProfile.driver,
    this.userName = 'Fulano Silva', // mudar p pegar do usuario ativo
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = switch (profile) {
      HomeProfile.driver => DriverHomeContent(userName: userName),
      HomeProfile.client => ClientHomeContent(userName: userName),
    };

    return HomeShell(content: content);
  }
}
