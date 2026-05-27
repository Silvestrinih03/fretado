import 'package:flutter/foundation.dart';

import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/models/driver_document_model.dart';
import '../../data/repositories/driver_document_repository.dart';

class MyDocumentsStore extends ChangeNotifier {
  final DriverDocumentRepository _documentRepository;
  final MyselfService _myselfService;
  final int? _fallbackUserId;

  MyDocumentsStore(
    this._documentRepository,
    this._myselfService, {
    int? fallbackUserId,
  }) : _fallbackUserId = fallbackUserId;

  bool _isLoading = false;
  String? _errorMessage;
  DriverDocumentModel? _driverDocument;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DriverDocumentModel? get driverDocument => _driverDocument;

  Future<void> loadDriverDocument() async {
    final userId = _myselfService.currentUserId ?? _fallbackUserId;
    if (userId == null) {
      _errorMessage = 'Usuário logado não encontrado.';
      _driverDocument = null;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      _driverDocument = await _documentRepository.getDriverDocumentByUser(
        userId,
      );
    } on DriverDocumentRepositoryException catch (e) {
      _errorMessage = e.message;
      _driverDocument = null;
    } catch (_) {
      _errorMessage = 'Não foi possível carregar seus documentos.';
      _driverDocument = null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
