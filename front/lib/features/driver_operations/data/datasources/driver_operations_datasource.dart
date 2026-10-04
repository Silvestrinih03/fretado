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

      return _readList(
        response,
      ).whereType<Map<String, dynamic>>().map(RideOfferModel.fromJson).toList();
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<RideOfferModel> acceptOffer(int offerId, int driverUserId) async {
    try {
      final response = await _httpService.put(
        Endpoints.acceptOffer(offerId, driverUserId),
      );
      return RideOfferModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<RideOfferModel> rejectOffer(int offerId, int driverUserId) async {
    try {
      final response = await _httpService.put(
        Endpoints.rejectOffer(offerId, driverUserId),
      );
      return RideOfferModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<List<DriverRideModel>> listRidesInProgressByUser(int userId) async {
    try {
      final response = await _httpService.get(
        Endpoints.ridesInProgressByUser(userId),
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

  Future<RidePickupEstimateModel> getPickupEstimate(int rideId) async {
    try {
      final response = await _httpService.get(
        Endpoints.ridePickupEstimate(rideId),
      );
      return RidePickupEstimateModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<double> getRouteDistance(DriverRideModel ride) async {
    final details = ride.details;
    if (details == null) {
      throw const DriverOperationsDatasourceException(
        'A corrida nao possui coordenadas da rota.',
      );
    }

    try {
      final response = await _httpService.get(
        Endpoints.rideRoutePreview(
          originLatitude: details.originLatitude,
          originLongitude: details.originLongitude,
          destinationLatitude: details.destinationLatitude,
          destinationLongitude: details.destinationLongitude,
        ),
      );
      final distance = double.tryParse(
        response['distance_km']?.toString() ?? '',
      );
      if (distance == null || !distance.isFinite || distance < 0) {
        throw const FormatException('Distancia da rota invalida.');
      }
      return distance;
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<DriverRideModel> startRide(int rideId) async {
    try {
      final response = await _httpService.patch(Endpoints.startRide(rideId));
      return DriverRideModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<DriverRideModel> completeRidePickup(int rideId) async {
    try {
      final response = await _httpService.patch(
        Endpoints.completeRidePickup(rideId),
      );
      return DriverRideModel.fromJson(response);
    } on HttpServiceException catch (e) {
      throw DriverOperationsDatasourceException(
        e.message,
        statusCode: e.statusCode,
      );
    }
  }

  Future<DriverRideModel> finishRide(int rideId) async {
    try {
      final response = await _httpService.patch(Endpoints.finishRide(rideId));
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

  const DriverOperationsDatasourceException(this.message, {this.statusCode});

  @override
  String toString() =>
      'DriverOperationsDatasourceException($statusCode): $message';
}
