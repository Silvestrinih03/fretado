import '../datasources/driver_license_category_datasource.dart';
import '../models/driver_license_category_model.dart';
import 'driver_license_category_repository.dart';

class DriverLicenseCategoryRepositoryImpl
    implements DriverLicenseCategoryRepository {
  final DriverLicenseCategoryDatasource _datasource;

  const DriverLicenseCategoryRepositoryImpl(this._datasource);

  @override
  Future<List<DriverLicenseCategoryModel>> listDriverLicenseCategories() async {
    try {
      return await _datasource.listDriverLicenseCategories();
    } on DriverLicenseCategoryDatasourceException catch (e) {
      throw DriverLicenseCategoryRepositoryException(e.message);
    }
  }
}
