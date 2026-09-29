import '../../domain/repositories/ride_cancellation_repository.dart';
import '../datasources/ride_cancellation_datasource.dart';
import '../models/ride_cancellation_models.dart';

class RideCancellationRepositoryImpl implements RideCancellationRepository {
  final RideCancellationDatasource _datasource;
  const RideCancellationRepositoryImpl(this._datasource);

  @override
  Future<RideCancellationPreviewModel> preview(int rideId) =>
      _datasource.preview(rideId);
  @override
  Future<RideCancellationModel?> latest(int rideId) =>
      _datasource.latest(rideId);
  @override
  Future<RideCancellationModel> request(
    int rideId,
    RideCancellationRequestModel request,
  ) => _datasource.request(rideId, request);
  @override
  Future<RideCancellationModel?> driverAction() => _datasource.driverAction();
  @override
  Future<RideCancellationModel> confirmCargo(int cancellationId) =>
      _datasource.confirmCargo(cancellationId);
  @override
  Future<RideCancellationModel> decide(int cancellationId, bool accept) =>
      _datasource.decide(cancellationId, accept);
  @override
  Future<RideCancellationModel> acknowledge(int cancellationId) =>
      _datasource.acknowledge(cancellationId);
  @override
  Future<List<CancellationAddressModel>> searchAddress(String query) =>
      _datasource.searchAddress(query);
}
