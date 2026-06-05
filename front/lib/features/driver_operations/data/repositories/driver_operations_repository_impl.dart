import '../datasources/driver_operations_datasource.dart';
import '../models/driver_operation_models.dart';
import 'driver_operations_repository.dart';

class DriverOperationsRepositoryImpl implements DriverOperationsRepository {
  final DriverOperationsDatasource _datasource;

  const DriverOperationsRepositoryImpl(this._datasource);

  @override
  Future<List<RideOfferModel>> listOffersByDriver(int driverUserId) async {
    try {
      return await _datasource.listOffersByDriver(driverUserId);
    } on DriverOperationsDatasourceException catch (e) {
      throw DriverOperationsRepositoryException(e.message);
    }
  }

  @override
  Future<RideOfferModel> acceptOffer(int offerId) async {
    try {
      return await _datasource.acceptOffer(offerId);
    } on DriverOperationsDatasourceException catch (e) {
      throw DriverOperationsRepositoryException(e.message);
    }
  }

  @override
  Future<RideOfferModel> rejectOffer(int offerId) async {
    try {
      return await _datasource.rejectOffer(offerId);
    } on DriverOperationsDatasourceException catch (e) {
      throw DriverOperationsRepositoryException(e.message);
    }
  }

  @override
  Future<List<DriverRideModel>> listRidesByDriver(int driverUserId) async {
    try {
      return await _datasource.listRidesByDriver(driverUserId);
    } on DriverOperationsDatasourceException catch (e) {
      throw DriverOperationsRepositoryException(e.message);
    }
  }

  @override
  Future<List<DriverRideModel>> listRidesByClient(int clientUserId) async {
    try {
      return await _datasource.listRidesByClient(clientUserId);
    } on DriverOperationsDatasourceException catch (e) {
      throw DriverOperationsRepositoryException(e.message);
    }
  }

  @override
  Future<List<DriverRideModel>> listRidesInProgressByUser(int userId) async {
    try {
      return await _datasource.listRidesInProgressByUser(userId);
    } on DriverOperationsDatasourceException catch (e) {
      throw DriverOperationsRepositoryException(e.message);
    }
  }

  @override
  Future<DriverRideModel> getRideById(int rideId) async {
    try {
      return await _datasource.getRideById(rideId);
    } on DriverOperationsDatasourceException catch (e) {
      throw DriverOperationsRepositoryException(e.message);
    }
  }

  @override
  Future<DriverWalletModel?> getWalletByDriver(int driverUserId) async {
    try {
      return await _datasource.getWalletByDriver(driverUserId);
    } on DriverOperationsDatasourceException catch (e) {
      throw DriverOperationsRepositoryException(e.message);
    }
  }

  @override
  Future<List<WalletTransactionModel>> listTransactionsByDriver(
    int driverUserId,
  ) async {
    try {
      return await _datasource.listTransactionsByDriver(driverUserId);
    } on DriverOperationsDatasourceException catch (e) {
      throw DriverOperationsRepositoryException(e.message);
    }
  }

  @override
  Future<WalletTransactionModel> requestWithdraw({
    required int driverUserId,
    required WalletWithdrawRequestModel request,
  }) async {
    try {
      return await _datasource.requestWithdraw(
        driverUserId: driverUserId,
        request: request,
      );
    } on DriverOperationsDatasourceException catch (e) {
      throw DriverOperationsRepositoryException(e.message);
    }
  }

  @override
  Future<List<DriverEarningModel>> listEarningsByDriver(
    int driverUserId,
  ) async {
    try {
      return await _datasource.listEarningsByDriver(driverUserId);
    } on DriverOperationsDatasourceException catch (e) {
      throw DriverOperationsRepositoryException(e.message);
    }
  }
}
