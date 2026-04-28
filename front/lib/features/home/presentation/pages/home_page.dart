import 'package:flutter/material.dart';

import '../../../../core/services/myself/services/myself_service.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../../core/services/myself/models/myself_user_model.dart';
import '../widgets/client_home_content.dart';
import '../widgets/driver_home_content.dart';
import '../widgets/home_shell.dart';

class HomePage extends StatefulWidget {
  final HomeProfileEnum profile;
  final String userName;

  const HomePage({
    super.key,
    this.profile = HomeProfileEnum.driver,
    this.userName = '', // mudar p pegar do usuario ativo
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final MyselfService _myselfService;
  late final Future<MyselfUserModel> _myselfFuture;

  @override
  void initState() {
    super.initState();
    _myselfService = MyselfService();
    _myselfFuture = _myselfService.getMyself(5);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MyselfUserModel>(
      future: _myselfFuture,
      builder: (context, snapshot) {
        final String firstName = snapshot.data?.firstName.isNotEmpty == true
            ? snapshot.data!.firstName
            : widget.userName;

        final Widget content = switch (widget.profile) {
          HomeProfileEnum.driver => DriverHomeContent(firstName: firstName),
          HomeProfileEnum.client => ClientHomeContent(userName: firstName),
        };

        return HomeShell(content: content);
      },
    );
  }
}
