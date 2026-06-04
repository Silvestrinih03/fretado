import '../models/driver_operation_models.dart';

abstract class DriverOperationsRepository {
  Future<List<RideOfferModel>> listOffersByDriver(int driverUserId);

  Future<RideOfferModel> acceptOffer(int offerId);

  Future<RideOfferModel> rejectOffer(int offerId);

  Future<List<DriverRideModel>> listRidesByDriver(int driverUserId);

  Future<DriverRideModel> getRideById(int rideId);

  Future<DriverWalletModel?> getWalletByDriver(int driverUserId);

  Future<List<WalletTransactionModel>> listTransactionsByDriver(
    int driverUserId,
  );

  Future<WalletTransactionModel> requestWithdraw({
    required int driverUserId,
    required WalletWithdrawRequestModel request,
  });

  Future<List<DriverEarningModel>> listEarningsByDriver(int driverUserId);
}

class DriverOperationsRepositoryException implements Exception {
  final String message;

  const DriverOperationsRepositoryException(this.message);

  @override
  String toString() => 'DriverOperationsRepositoryException: $message';
}
