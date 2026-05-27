import '../models/driver_document_model.dart';

abstract class DriverDocumentRepository {
  Future<DriverDocumentModel?> getDriverDocumentByUser(int userId);

  Future<DriverDocumentModel> createDriverDocument({
    required int userId,
    required DriverDocumentModel document,
  });

  Future<DriverDocumentModel> updateDriverDocument({
    required int documentId,
    required DriverDocumentModel document,
  });
}

class DriverDocumentRepositoryException implements Exception {
  final String message;

  const DriverDocumentRepositoryException(this.message);

  @override
  String toString() {
    return 'DriverDocumentRepositoryException: $message';
  }
}
