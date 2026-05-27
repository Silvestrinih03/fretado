import '../models/driver_license_category_model.dart';

abstract class DriverLicenseCategoryRepository {
  Future<List<DriverLicenseCategoryModel>> listDriverLicenseCategories();
}

class DriverLicenseCategoryRepositoryException implements Exception {
  final String message;

  const DriverLicenseCategoryRepositoryException(this.message);

  @override
  String toString() {
    return 'DriverLicenseCategoryRepositoryException: $message';
  }
}
