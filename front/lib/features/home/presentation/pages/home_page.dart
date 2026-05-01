import 'package:flutter/material.dart';

import '../../../../core/enums/home_profile.dart';
import '../../../../core/services/myself/models/myself_user_model.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../widgets/client_home_content.dart';
import '../widgets/driver_home_content.dart';
import '../widgets/home_shell.dart';

class HomePage extends StatefulWidget {
  final HomeProfileEnum profile;
  final int? userId;

  const HomePage({
    super.key,
    this.profile = HomeProfileEnum.driver,
    this.userId,
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
    if (widget.userId != null) {
      _myselfService.currentUserId = widget.userId;
    }

    _myselfFuture = _myselfService.getMyself(
      widget.userId ?? _myselfService.currentUserId ?? 5,
    );
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
            : '';

        final Widget content = switch (widget.profile) {
          HomeProfileEnum.driver => DriverHomeContent(
              firstName: firstName,
              userId: widget.userId ?? _myselfService.currentUserId ?? 5,
            ),
          HomeProfileEnum.client => ClientHomeContent(userName: firstName),
        };

        return HomeShell(content: content);
      },
    );
  }
}
