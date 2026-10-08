import '../../data/models/ride_cancellation_models.dart';

abstract class RideCancellationRepository {
  Future<RideCancellationPreviewModel> preview(int rideId);
  Future<RideCancellationModel?> latest(int rideId);
  Future<RideCancellationModel> request(
    int rideId,
    RideCancellationRequestModel request,
  );
  Future<RideCancellationModel?> driverAction();
  Future<RideCancellationModel> prepareDriverQuote(int cancellationId);
  Future<RideCancellationModel> confirmCargo(int cancellationId);
  Future<RideCancellationModel> decide(int cancellationId, bool accept);
  Future<RideCancellationModel> acknowledge(int cancellationId);
  Future<List<CancellationAddressModel>> searchAddress(String query);
}
