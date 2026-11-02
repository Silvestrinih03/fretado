import '../../../core/endpoints.dart';
import '../../../core/services/http_service.dart';
import '../../driver_operations/data/models/driver_operation_models.dart';

class DriverNavigationRepository {
  final HttpService _http;

  DriverNavigationRepository({HttpService? http})
    : _http = http ?? HttpService();

  String get baseUrl => _http.baseUrl;

  Future<DriverRideModel> ride(int id) async =>
      DriverRideModel.fromJson(await _http.get(Endpoints.rideById(id)));

  Future<DriverRideModel> advance(DriverRideModel ride) async =>
      DriverRideModel.fromJson(
        await _http.patch(
          ride.statusId == 3
              ? Endpoints.completeRidePickup(ride.id)
              : Endpoints.finishRide(ride.id),
        ),
      );

  void dispose() => _http.dispose();
}
