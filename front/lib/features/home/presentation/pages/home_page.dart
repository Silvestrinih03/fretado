import 'package:flutter/material.dart';

import '../../../../core/enums/home_profile.dart';
import '../../../../core/services/myself/models/myself_user_model.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../controllers/driver_availability_controller.dart';
import '../widgets/client_home_shell.dart';
import '../widgets/driver_home_content.dart';
import '../widgets/home_shell.dart';

class HomePage extends StatefulWidget {
  final HomeProfileEnum profile;
  final int? userId;
  final int? userTypeId;

  const HomePage({
    super.key,
    this.profile = HomeProfileEnum.driver,
    this.userId,
    this.userTypeId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final MyselfService _myselfService;
  late final Future<MyselfUserModel> _myselfFuture;
  DriverAvailabilityController? _driverAvailabilityController;
  int? _driverAvailabilityUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _myselfService = MyselfService();
    if (widget.userId != null) {
      _myselfService.currentUserId = widget.userId;
    }
    if (widget.userTypeId != null) {
      _myselfService.currentUserTypeId = widget.userTypeId;
    }

    _myselfFuture = _myselfService.getMyself(
      widget.userId ?? _myselfService.currentUserId ?? 5,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _driverAvailabilityController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _driverAvailabilityController?.loadInitialStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MyselfUserModel>(
      future: _myselfFuture,
      builder: (context, snapshot) {
        final String firstName = snapshot.data?.firstName.isNotEmpty == true
            ? snapshot.data!.firstName
            : '';
        final int? userTypeId = widget.userTypeId ??
            _myselfService.currentUserTypeId ??
            snapshot.data?.userTypeId;
        final HomeProfileEnum profile = userTypeId != null
            ? HomeProfileMapper.fromUserTypeId(userTypeId)
            : widget.profile;

        final int resolvedUserId =
            widget.userId ?? _myselfService.currentUserId ?? 5;
        final DriverAvailabilityController? driverAvailability =
            profile == HomeProfileEnum.driver
                ? _availabilityControllerFor(resolvedUserId)
                : null;

        if (profile == HomeProfileEnum.client) {
          return ClientHomeShell(
            userName: firstName,
            userId: resolvedUserId,
          );
        }

        return HomeShell(
          content: DriverHomeContent(
            firstName: firstName,
            userId: resolvedUserId,
            availabilityController: driverAvailability!,
          ),
          userId: widget.userId ?? _myselfService.currentUserId,
          userTypeId: userTypeId,
          driverAvailabilityController: driverAvailability,
        );
      },
    );
  }

  DriverAvailabilityController _availabilityControllerFor(int userId) {
    final existing = _driverAvailabilityController;
    if (existing != null && _driverAvailabilityUserId == userId) {
      return existing;
    }

    existing?.dispose();
    final controller = DriverAvailabilityController();
    _driverAvailabilityController = controller;
    _driverAvailabilityUserId = userId;
    controller.loadInitialStatus();
    return controller;
  }
}
