import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../models/driver_operation_models.dart';

class DriverOperationsDatasource {
  final HttpService _httpService;

  const DriverOperationsDatasource(this._httpService);

  Future<List<RideOfferModel>> listOffersByDriver(int driverUserId) async {
    try {
      final response = await _httpService.get(
        Endpoints.offersByDriver(driverUserId),
      );

      return _readList(response)
          .whereType<Map<String, dynamic>>()
          .map(RideOfferModel.fromJson)
          .toList();
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<RideOfferModel> acceptOffer(int offerId) async {
    try {
      final response = await _httpService.put(Endpoints.acceptOffer(offerId));
      return RideOfferModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<RideOfferModel> rejectOffer(int offerId) async {
    try {
      final response = await _httpService.put(Endpoints.rejectOffer(offerId));
      return RideOfferModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<List<DriverRideModel>> listRidesByDriver(int driverUserId) async {
    try {
      final response = await _httpService.get(
        Endpoints.ridesByDriver(driverUserId),
      );

      return _readList(response)
          .whereType<Map<String, dynamic>>()
          .map(DriverRideModel.fromJson)
          .toList();
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<DriverRideModel> getRideById(int rideId) async {
    try {
      final response = await _httpService.get(Endpoints.rideById(rideId));
      return DriverRideModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<DriverWalletModel?> getWalletByDriver(int driverUserId) async {
    try {
      final response = await _httpService.get(
        Endpoints.driverWalletByDriver(driverUserId),
      );
      return DriverWalletModel.fromJson(response);
    } on HttpServiceException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }

      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<List<WalletTransactionModel>> listTransactionsByDriver(
    int driverUserId,
  ) async {
    try {
      final response = await _httpService.get(
        Endpoints.walletTransactionsByDriver(driverUserId),
      );

      return _readList(response)
          .whereType<Map<String, dynamic>>()
          .map(WalletTransactionModel.fromJson)
          .toList();
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<WalletTransactionModel> requestWithdraw({
    required int driverUserId,
    required WalletWithdrawRequestModel request,
  }) async {
    try {
      final response = await _httpService.post(
        Endpoints.walletTransactionsByDriver(driverUserId),
        body: request.toJson(),
      );

      return WalletTransactionModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<List<DriverEarningModel>> listEarningsByDriver(
    int driverUserId,
  ) async {
    try {
      final response = await _httpService.get(
        Endpoints.driverEarningsByDriver(driverUserId),
      );

      return _readList(response)
          .whereType<Map<String, dynamic>>()
          .map(DriverEarningModel.fromJson)
          .toList();
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  List<dynamic> _readList(Map<String, dynamic> response) {
    final dynamic data = response['data'];
    if (data is List<dynamic>) {
      return data;
    }
    return <dynamic>[];
  }
}

class DriverOperationsDatasourceException implements Exception {
  final String message;
  final int? statusCode;

  const DriverOperationsDatasourceException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() => 'DriverOperationsDatasourceException($statusCode): $message';
}
