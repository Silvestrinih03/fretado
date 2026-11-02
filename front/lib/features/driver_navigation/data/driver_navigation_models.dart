import 'package:latlong2/latlong.dart';

import '../../driver_operations/data/models/driver_operation_models.dart';

class NavigationDestination {
  final int statusId;
  final String address;
  final LatLng point;

  const NavigationDestination(this.statusId, this.address, this.point);

  bool get isPickup => statusId == 3;
  String get title => isPickup ? 'Ponto de coleta' : 'Ponto de entrega';
  String get routeLabel =>
      isPickup ? 'Ver rota até a coleta' : 'Ver rota até a entrega';
  String get key => '$statusId:${point.latitude}:${point.longitude}';

  static NavigationDestination? fromRide(DriverRideModel ride) {
    final details = ride.details;
    if ((ride.statusId != 3 && ride.statusId != 4) ||
        ride.hasActiveDriverReassignment ||
        details == null) {
      return null;
    }
    final pickup = ride.statusId == 3;
    final lat = pickup ? details.originLatitude : details.destinationLatitude;
    final lng = pickup ? details.originLongitude : details.destinationLongitude;
    if (!lat.isFinite || !lng.isFinite || lat.abs() > 90 || lng.abs() > 180) {
      return null;
    }
    return NavigationDestination(
      ride.statusId,
      pickup ? ride.originLabel : ride.destinationLabel,
      LatLng(lat, lng),
    );
  }
}
