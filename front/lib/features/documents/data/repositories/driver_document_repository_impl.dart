import '../datasources/driver_document_datasource.dart';
import '../models/driver_document_model.dart';
import 'driver_document_repository.dart';

class DriverDocumentRepositoryImpl implements DriverDocumentRepository {
  final DriverDocumentDatasource _datasource;

  const DriverDocumentRepositoryImpl(this._datasource);

  @override
  Future<DriverDocumentModel?> getDriverDocumentByUser(int userId) async {
    try {
      return await _datasource.getDriverDocumentByUser(userId);
    } on DriverDocumentDatasourceException catch (e) {
      throw DriverDocumentRepositoryException(e.message);
    }
  }

  @override
  Future<DriverDocumentModel> createDriverDocument({
    required int userId,
    required DriverDocumentModel document,
  }) async {
    try {
      return await _datasource.createDriverDocument(
        userId: userId,
        document: document,
      );
    } on DriverDocumentDatasourceException catch (e) {
      throw DriverDocumentRepositoryException(e.message);
    }
  }

  @override
  Future<DriverDocumentModel> updateDriverDocument({
    required int documentId,
    required DriverDocumentModel document,
  }) async {
    try {
      return await _datasource.updateDriverDocument(
        documentId: documentId,
        document: document,
      );
    } on DriverDocumentDatasourceException catch (e) {
      throw DriverDocumentRepositoryException(e.message);
    }
  }
}
