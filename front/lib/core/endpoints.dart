abstract class Endpoints {
  Endpoints._();

  static const String root = '/';

  static const String auth = '/auth';
  static String changePassword(int userId) => '$auth/change-password/$userId';

  static const String register = '/register';

  static const String users = '/users';
  static String userById(int userId) => '$users/$userId';

  static const String vehicles = '/vehicles';
  static String vehiclesByUser(int userId) => '$vehicles/user/$userId';
  static String vehicleById(int vehicleId) => '$vehicles/$vehicleId';
  static String updateVehicleById(int vehicleId) => '$vehicles/$vehicleId';
  static String deleteVehicleById(int vehicleId) => '$vehicles/$vehicleId';

  static const String vehicleTypes = '/vehicle-types';
  static String vehicleTypeById(int vehicleTypeId) =>
      '$vehicleTypes/$vehicleTypeId';

  static const String vehicleCatalog = '/vehicle-catalog';
  static String vehicleCatalogBrands({
    required int vehicleTypeId,
    String? search,
  }) =>
      '$vehicleCatalog/brands?vehicle_type_id=$vehicleTypeId${_searchQuery(search)}';
  static String vehicleCatalogModels({
    required int vehicleTypeId,
    required String brandId,
    String? search,
  }) =>
      '$vehicleCatalog/models?vehicle_type_id=$vehicleTypeId&brand_id=$brandId${_searchQuery(search)}';
  static String vehicleCatalogYears({
    required int vehicleTypeId,
    required String brandId,
    required String modelId,
  }) =>
      '$vehicleCatalog/years?vehicle_type_id=$vehicleTypeId&brand_id=$brandId&model_id=$modelId';

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

  static String _searchQuery(String? search) {
    if (search == null || search.trim().isEmpty) {
      return '';
    }

    return '&search=${Uri.encodeQueryComponent(search.trim())}';
  }
}
