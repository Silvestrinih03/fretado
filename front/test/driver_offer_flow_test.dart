import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front/features/driver_operations/data/models/driver_operation_models.dart';
import 'package:front/features/driver_operations/data/repositories/driver_operations_repository.dart';
import 'package:front/features/driver_operations/presentation/controllers/driver_offer_controller.dart';
import 'package:front/features/driver_operations/presentation/pages/driver_offer_page.dart';
import 'package:front/features/driver_operations/presentation/widgets/driver_offer_gate.dart';

void main() {
  test(
    'parses timestamps with and without timezone and ignores expires_at',
    () {
      final withoutTimezone = _offerFromJson(
        createdAt: '2026-09-24T12:30:45',
        expiresAt: '2020-01-01T00:00:00Z',
      );
      final withTimezone = _offerFromJson(
        createdAt: '2026-09-24T09:30:45-03:00',
        expiresAt: '2020-01-01T00:00:00Z',
      );

      expect(withoutTimezone.createdAt, DateTime.utc(2026, 9, 24, 12, 30, 45));
      expect(withTimezone.createdAt, DateTime.utc(2026, 9, 24, 12, 30, 45));
      expect(withoutTimezone.isPending, isTrue);
      expect(withoutTimezone.isExpired, isFalse);
    },
  );

  test('calculates driver net value without returning a negative amount', () {
    expect(
      _rideFromJson(totalPrice: 25.56, appFeeValue: 5).driverNetValue,
      20.56,
    );
    expect(_rideFromJson(totalPrice: 5, appFeeValue: 7).driverNetValue, 0);
  });

  testWidgets(
    'loads route distance once per offer and uses geographic fallback',
    (tester) async {
      final repository = _FakeDriverOperationsRepository(routeFails: true);
      final controller = DriverOfferController(
        repository: repository,
        userId: 9,
        pollInterval: const Duration(days: 1),
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(controller.state, DriverOfferState.pending);
      expect(controller.pending?.distanceIsApproximate, isTrue);
      expect(controller.pending!.distanceKm, greaterThan(0));
      expect(repository.routeLoads, 1);

      await controller.refresh();
      expect(repository.routeLoads, 1);
      await controller.refresh(forceDetails: true);
      expect(repository.routeLoads, 1);
      controller.dispose();
    },
  );

  testWidgets('pauses checks in background and checks immediately on resume', (
    tester,
  ) async {
    final repository = _FakeDriverOperationsRepository();
    final controller = DriverOfferController(
      repository: repository,
      userId: 9,
      pollInterval: const Duration(milliseconds: 20),
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    final pausedLoads = repository.offerLoads;
    await controller.refresh();
    await tester.pump(const Duration(milliseconds: 45));
    expect(repository.offerLoads, pausedLoads);

    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    await controller.refresh();
    expect(repository.offerLoads, greaterThan(pausedLoads));
    controller.dispose();
  });

  testWidgets('keeps offer and error visible when accept fails', (
    tester,
  ) async {
    final repository = _FakeDriverOperationsRepository(actionFails: true);
    final controller = DriverOfferController(
      repository: repository,
      userId: 9,
      pollInterval: const Duration(days: 1),
    );
    addTearDown(controller.dispose);
    await controller.refresh();

    expect(await controller.respond(accept: true), isFalse);
    expect(controller.pending, isNotNull);
    expect(controller.state, DriverOfferState.pending);
    expect(controller.error, 'Falha controlada');
    controller.dispose();
  });

  testWidgets('accept, reject and remote disappearance clear the gate state', (
    tester,
  ) async {
    final acceptController = await _loadedController();
    addTearDown(acceptController.dispose);
    expect(await acceptController.respond(accept: true), isTrue);
    expect(acceptController.state, DriverOfferState.idle);
    acceptController.dispose();

    final rejectController = await _loadedController();
    addTearDown(rejectController.dispose);
    expect(await rejectController.respond(accept: false), isTrue);
    expect(rejectController.state, DriverOfferState.idle);
    rejectController.dispose();

    final repository = _FakeDriverOperationsRepository();
    final remoteController = DriverOfferController(
      repository: repository,
      userId: 9,
      pollInterval: const Duration(days: 1),
    );
    addTearDown(remoteController.dispose);
    await remoteController.refresh();
    repository.hasOffer = false;
    await remoteController.refresh();
    expect(remoteController.pending, isNull);
    expect(remoteController.state, DriverOfferState.idle);
    remoteController.dispose();
  });

  testWidgets('offer matches content at 390x844', (tester) async {
    await _setSurface(tester, const Size(390, 844));
    final controller = await _loadedController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: DriverOfferPage(controller: controller)),
    );
    await tester.pump();

    expect(find.text('NOVA SOLICITAÇÃO'), findsOneWidget);
    expect(find.text('Corrida #34'), findsOneWidget);
    expect(find.text('Você receberá'), findsOneWidget);
    expect(find.text('R\$ 20,56'), findsOneWidget);
    expect(find.text('Rota da entrega'), findsOneWidget);
    expect(find.text('Recusar'), findsOneWidget);
    expect(find.text('Aceitar corrida'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(DriverOfferPage),
      matchesGoldenFile('goldens/driver_offer_page_390x844.png'),
    );
    controller.dispose();
  });

  testWidgets('offer remains usable at 320px without overflow', (tester) async {
    await _setSurface(tester, const Size(320, 700));
    final controller = await _loadedController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: DriverOfferPage(controller: controller)),
    );
    await tester.pump();

    expect(find.text('Aceitar corrida'), findsOneWidget);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('gate leaves an idle driver free and blocks a pending driver', (
    tester,
  ) async {
    var taps = 0;
    final idleController = DriverOfferController(
      repository: _FakeDriverOperationsRepository(hasOffer: false),
      userId: 9,
      pollInterval: const Duration(days: 1),
    );
    addTearDown(idleController.dispose);
    await idleController.refresh();

    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => DriverOfferGate.forTesting(
          controller: idleController,
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => taps++,
              child: const Text('Ação da Home'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ação da Home'));
    expect(taps, 1);

    final pendingController = await _loadedController();
    addTearDown(pendingController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => DriverOfferGate.forTesting(
          controller: pendingController,
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => taps++,
              child: const Text('Ação da Home'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('NOVA SOLICITAÇÃO'), findsOneWidget);
    await tester.tap(find.text('Ação da Home'), warnIfMissed: false);
    expect(taps, 1);
    idleController.dispose();
    pendingController.dispose();
  });
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<DriverOfferController> _loadedController() async {
  final controller = DriverOfferController(
    repository: _FakeDriverOperationsRepository(),
    userId: 9,
    pollInterval: const Duration(days: 1),
  );
  await controller.refresh();
  return controller;
}

class _FakeDriverOperationsRepository implements DriverOperationsRepository {
  final bool routeFails;
  final bool actionFails;
  bool hasOffer;
  int offerLoads = 0;
  int routeLoads = 0;

  _FakeDriverOperationsRepository({
    this.routeFails = false,
    this.actionFails = false,
    this.hasOffer = true,
  });

  @override
  Future<List<RideOfferModel>> listOffersByDriver(int driverUserId) async {
    offerLoads++;
    return hasOffer ? <RideOfferModel>[_offerFromJson()] : <RideOfferModel>[];
  }

  @override
  Future<DriverRideModel> getRideById(int rideId) async => _rideFromJson();

  @override
  Future<double> getRouteDistance(DriverRideModel ride) async {
    routeLoads++;
    if (routeFails) {
      throw const DriverOperationsRepositoryException('Mapbox indisponível');
    }
    return 12;
  }

  @override
  Future<RideOfferModel> acceptOffer(int offerId, int driverUserId) async {
    if (actionFails) {
      throw const DriverOperationsRepositoryException('Falha controlada');
    }
    return _offerFromJson(statusId: 2);
  }

  @override
  Future<RideOfferModel> rejectOffer(int offerId, int driverUserId) async =>
      _offerFromJson(statusId: 3);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RideOfferModel _offerFromJson({
  int statusId = 1,
  String? createdAt,
  String? expiresAt,
}) => RideOfferModel.fromJson(<String, dynamic>{
  'id': 12,
  'ride_id': 34,
  'driver_user_id': 9,
  'vehicle_id': 4,
  'status_id': statusId,
  'created_at': createdAt ?? DateTime.now().toUtc().toIso8601String(),
  'expires_at': expiresAt ?? '9999-12-31T23:59:59Z',
});

DriverRideModel _rideFromJson({
  double totalPrice = 25.56,
  double appFeeValue = 5,
}) => DriverRideModel.fromJson(<String, dynamic>{
  'id': 34,
  'client_user_id': 2,
  'driver_user_id': null,
  'required_vehicle_type_id': 1,
  'required_vehicle_type_name': 'Hatch',
  'total_price': totalPrice,
  'app_fee_value': appFeeValue,
  'status_id': 1,
  'created_at': '2026-09-24T12:30:45Z',
  'details': <String, dynamic>{
    'id': 8,
    'ride_id': 34,
    'origin_address': 'Av. Brasil, 500 · Campinas',
    'origin_latitude': -22.9064,
    'origin_longitude': -47.0616,
    'destination_address': 'Rua das Flores, 78 · Valinhos',
    'destination_latitude': -22.9706,
    'destination_longitude': -46.9958,
    'package_width': 30,
    'package_height': 20,
    'package_length': 40,
    'package_weight': 18,
  },
});
