import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../models/ride_cancellation_models.dart';

class RideCancellationDatasource {
  final HttpService _http;
  const RideCancellationDatasource(this._http);

  Future<RideCancellationPreviewModel> preview(int rideId) async =>
      RideCancellationPreviewModel.fromJson(
        await _http.get(Endpoints.rideCancellationPreview(rideId)),
      );

  Future<RideCancellationModel?> latest(int rideId) async =>
      _readNullable(await _http.get(Endpoints.latestRideCancellation(rideId)));

  Future<RideCancellationModel> request(
    int rideId,
    RideCancellationRequestModel request,
  ) async => RideCancellationModel.fromJson(
    await _http.post(
      Endpoints.createRideCancellation(rideId),
      body: request.toJson(),
    ),
  );

  Future<RideCancellationModel?> driverAction() async =>
      _readNullable(await _http.get(Endpoints.driverCancellationAction));

  Future<RideCancellationModel> confirmCargo(int cancellationId) async =>
      RideCancellationModel.fromJson(
        await _http.post(Endpoints.confirmCancellationCargo(cancellationId)),
      );

  Future<RideCancellationModel> decide(int cancellationId, bool accept) async =>
      RideCancellationModel.fromJson(
        await _http.post(
          Endpoints.decideRideCancellation(cancellationId),
          body: {'accept': accept},
        ),
      );

  Future<RideCancellationModel> acknowledge(int cancellationId) async =>
      RideCancellationModel.fromJson(
        await _http.post(Endpoints.acknowledgeRideCancellation(cancellationId)),
      );

  Future<List<CancellationAddressModel>> searchAddress(String query) async {
    final response = await _http.get(Endpoints.rideGeocode(query));
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(CancellationAddressModel.fromJson)
        .where((item) => item.label.isNotEmpty)
        .toList();
  }

  RideCancellationModel? _readNullable(Map<String, dynamic> json) {
    if (json['id'] != null) return RideCancellationModel.fromJson(json);
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return RideCancellationModel.fromJson(data);
    }
    return null;
  }
}
