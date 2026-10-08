abstract class Endpoints {
  Endpoints._();

  static const String root = '/';

  static const String auth = '/auth';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';
  static String changePassword(int userId) => '$auth/change-password/$userId';

  static const String register = '/register';

  static const String users = '/users';
  static String userById(int userId) => '$users/$userId';

  static const String vehicles = '/vehicles';
  static String vehiclesByUser(int userId) => '$vehicles/user/$userId';
  static String vehicleById(int vehicleId) => '$vehicles/$vehicleId';
  static String updateVehicleById(int vehicleId) => '$vehicles/$vehicleId';
  static String deleteVehicleById(int vehicleId) => '$vehicles/$vehicleId';

  static const String rides = '/rides';
  static String rideById(int rideId) => '$rides/$rideId';
  static String ridePickupEstimate(int rideId) =>
      '$rides/$rideId/pickup-estimate';
  static String ridesMe({
    String statusGroup = 'all',
    int limit = 20,
    String? cursor,
  }) {
    final queryParameters = <String, String>{
      'status_group': statusGroup,
      'limit': limit.toString(),
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };
    return Uri(path: '$rides/me', queryParameters: queryParameters).toString();
  }

  static String ridesInProgressByUser(int userId) =>
      '$rides/in-progress/user/$userId';
  static String rideGeocode(String query) =>
      '$rides/geocode?q=${Uri.encodeQueryComponent(query.trim())}';
  static String rideReverseGeocode({
    required double latitude,
    required double longitude,
  }) =>
      '$rides/reverse-geocode?latitude=${Uri.encodeQueryComponent(latitude.toString())}&longitude=${Uri.encodeQueryComponent(longitude.toString())}';
  static String rideRoutePreview({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) =>
      '$rides/route?origin_latitude=${Uri.encodeQueryComponent(originLatitude.toString())}&origin_longitude=${Uri.encodeQueryComponent(originLongitude.toString())}&destination_latitude=${Uri.encodeQueryComponent(destinationLatitude.toString())}&destination_longitude=${Uri.encodeQueryComponent(destinationLongitude.toString())}';
  static const String rideQuote = '$rides/quote';
  static const String createRide = '$rides/create';
  static String startRide(int rideId) => '$rides/$rideId/start';
  static String completeRidePickup(int rideId) =>
      '$rides/$rideId/pickup-completed';
  static String finishRide(int rideId) => '$rides/$rideId/finish';
  static String rideCancellationPreview(int rideId) =>
      '$rides/$rideId/cancellation-preview';
  static String createRideCancellation(int rideId) =>
      '$rides/$rideId/cancellations';
  static String latestRideCancellation(int rideId) =>
      '$rides/$rideId/cancellations/latest';

  static const String driverCancellationAction =
      '/ride-cancellations/driver/me/action-required';
  static String prepareCancellationDriverQuote(int cancellationId) =>
      '/ride-cancellations/$cancellationId/driver-quote';
  static String confirmCancellationCargo(int cancellationId) =>
      '/ride-cancellations/$cancellationId/driver-confirm';
  static String decideRideCancellation(int cancellationId) =>
      '/ride-cancellations/$cancellationId/client-decision';
  static String acknowledgeRideCancellation(int cancellationId) =>
      '/ride-cancellations/$cancellationId/driver-acknowledge';
  static String rideCancellationLog(int rideId) =>
      '$rides/$rideId/cancellation-log';

  static const String rideOffers = '/offers';
  static String offersByDriver(int driverUserId) =>
      '$rideOffers/driver/$driverUserId';
  static String acceptOffer(int offerId, int driverUserId) =>
      '$rideOffers/$offerId/accept?driver_user_id=$driverUserId';
  static String rejectOffer(int offerId, int driverUserId) =>
      '$rideOffers/$offerId/reject?driver_user_id=$driverUserId';

  static const String driverLocations = '/driver-locations';
  static const String driverLocationMe = '$driverLocations/me';
  static const String driverLocationMeOnline = '$driverLocations/me/online';
  static const String driverLocationMeOffline = '$driverLocations/me/offline';
  static const String driverLocationMeLocation = '$driverLocations/me/location';
  static String driverLocationByDriver(int driverUserId) =>
      '$driverLocations/$driverUserId';
  static String driverLocationOffline(int driverUserId) =>
      '$driverLocations/$driverUserId/offline';

  static const String driverEarnings = '/driver_earnings';
  static String driverEarningsByDriver(int driverUserId) =>
      '$driverEarnings/driver/$driverUserId';

  static const String driverWallets = '/driver_wallets';
  static String driverWalletByDriver(int driverUserId) =>
      '$driverWallets/driver/$driverUserId';

  static const String walletTransactions = '/wallet_transactions';
  static String walletTransactionsByDriver(int driverUserId) =>
      '$walletTransactions/driver/$driverUserId';

  static const String cards = '/cards';
  static const String createCard = '$cards/';
  static String cardsByUser(int userId) => '$cards/user/$userId';
  static String cardByUser({required int userId, required int cardId}) =>
      '$cards/user/$userId/$cardId';

  static const String vehicleTypes = '/vehicle-types';
  static String vehicleTypeById(int vehicleTypeId) =>
      '$vehicleTypes/$vehicleTypeId';

  static const String vehicleCatalog = '/vehicle-catalog';
  static String vehicleCatalogBrands() => '$vehicleCatalog/brands';
  static String vehicleCatalogModels({required String brandId}) =>
      '$vehicleCatalog/models?brand_id=${Uri.encodeQueryComponent(brandId)}';
  static String vehicleCatalogVersions({
    required String brandId,
    required String modelId,
  }) =>
      '$vehicleCatalog/versions?brand_id=${Uri.encodeQueryComponent(brandId)}&model_id=${Uri.encodeQueryComponent(modelId)}';

  static const String driverLicenseCategories = '/driver-license-categories';
  static String driverLicenseCategoryById(int categoryId) =>
      '$driverLicenseCategories/$categoryId';

  static const String driverDocuments = '/driver_documents';
  static const String driverDocumentCategories = '$driverDocuments/categories';
  static String driverDocumentByUserId(int userId) =>
      '$driverDocuments/user/$userId';
  static String createDriverDocumentForUser(int userId) =>
      '$driverDocuments/user/$userId';
  static String updateDriverDocument(int documentId) =>
      '$driverDocuments/$documentId';
}
