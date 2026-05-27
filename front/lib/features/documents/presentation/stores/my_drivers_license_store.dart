import 'package:flutter/foundation.dart';

import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/models/driver_document_model.dart';
import '../../data/models/driver_license_category_model.dart';
import '../../data/repositories/driver_document_repository.dart';
import '../../data/repositories/driver_license_category_repository.dart';

class MyDriversLicenseStore extends ChangeNotifier {
  final DriverLicenseCategoryRepository _categoryRepository;
  final DriverDocumentRepository _documentRepository;
  final MyselfService _myselfService;
  final int? _fallbackUserId;

  MyDriversLicenseStore(
    this._categoryRepository,
    this._documentRepository,
    this._myselfService, {
    int? fallbackUserId,
  }) : _fallbackUserId = fallbackUserId;

  bool _isLoadingCategories = false;
  bool _isLoadingDocument = false;
  bool _isSavingDocument = false;
  String? _categoriesError;
  String? _loadDocumentError;
  String? _saveDocumentError;
  List<DriverLicenseCategoryModel> _categories =
      <DriverLicenseCategoryModel>[];
  int? _selectedCategoryId;
  DriverDocumentModel? _driverDocument;

  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingDocument => _isLoadingDocument;
  bool get isSavingDocument => _isSavingDocument;
  String? get categoriesError => _categoriesError;
  String? get loadDocumentError => _loadDocumentError;
  String? get saveDocumentError => _saveDocumentError;
  List<DriverLicenseCategoryModel> get categories {
    return List<DriverLicenseCategoryModel>.unmodifiable(_categories);
  }

  int? get selectedCategoryId => _selectedCategoryId;
  DriverDocumentModel? get driverDocument => _driverDocument;
  bool get hasDriverDocument => _driverDocument?.id != null;

  Future<void> loadCategories() async {
    _setLoadingCategories(true);
    _categoriesError = null;

    try {
      _categories = await _categoryRepository.listDriverLicenseCategories();
    } on DriverLicenseCategoryRepositoryException catch (e) {
      _categoriesError = e.message;
    } catch (_) {
      _categoriesError =
          'Não foi possível carregar as categorias da CNH.';
    } finally {
      _setLoadingCategories(false);
    }
  }

  void selectCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    _saveDocumentError = null;
    notifyListeners();
  }

  Future<void> loadDriverDocument() async {
    final userId = _myselfService.currentUserId ?? _fallbackUserId;
    if (userId == null) {
      _loadDocumentError = 'Usuário logado não encontrado.';
      notifyListeners();
      return;
    }

    _setLoadingDocument(true);
    _loadDocumentError = null;

    try {
      _driverDocument = await _documentRepository.getDriverDocumentByUser(
        userId,
      );
      _selectedCategoryId = _driverDocument?.licenseCategoryId;
    } on DriverDocumentRepositoryException catch (e) {
      _loadDocumentError = e.message;
    } catch (_) {
      _loadDocumentError = 'Não foi possível carregar sua CNH.';
    } finally {
      _setLoadingDocument(false);
    }
  }

  Future<bool> saveDriverDocument({
    required String licenseNumber,
    required DateTime? issueDate,
    required DateTime? expirationDate,
  }) async {
    final userId = _myselfService.currentUserId ?? _fallbackUserId;
    if (userId == null) {
      _saveDocumentError = 'Usuário logado não encontrado.';
      notifyListeners();
      return false;
    }

    if (_selectedCategoryId == null) {
      _saveDocumentError = 'Selecione a categoria da sua CNH.';
      notifyListeners();
      return false;
    }

    final cleanedLicenseNumber = licenseNumber.trim();
    if (cleanedLicenseNumber.isEmpty) {
      _saveDocumentError = 'Informe o número de registro da CNH.';
      notifyListeners();
      return false;
    }

    if (issueDate == null) {
      _saveDocumentError = 'Informe a data de emissão.';
      notifyListeners();
      return false;
    }

    if (expirationDate == null) {
      _saveDocumentError = 'Informe a data de validade.';
      notifyListeners();
      return false;
    }

    if (!expirationDate.isAfter(issueDate)) {
      _saveDocumentError =
          'A data de validade deve ser posterior à data de emissão.';
      notifyListeners();
      return false;
    }

    _setSavingDocument(true);
    _saveDocumentError = null;

    try {
      final document = DriverDocumentModel(
        licenseNumber: cleanedLicenseNumber,
        licenseCategoryId: _selectedCategoryId!,
        issueDate: _formatApiDate(issueDate),
        expirationDate: _formatApiDate(expirationDate),
      );

      final documentId = _driverDocument?.id;
      if (documentId == null) {
        _driverDocument = await _documentRepository.createDriverDocument(
          userId: userId,
          document: document,
        );
      } else {
        _driverDocument = await _documentRepository.updateDriverDocument(
          documentId: documentId,
          document: document,
        );
      }

      return true;
    } on DriverDocumentRepositoryException catch (e) {
      _saveDocumentError = e.message;
      return false;
    } catch (_) {
      _saveDocumentError = 'Não foi possível salvar sua CNH agora.';
      return false;
    } finally {
      _setSavingDocument(false);
    }
  }

  void _setLoadingCategories(bool value) {
    _isLoadingCategories = value;
    notifyListeners();
  }

  void _setLoadingDocument(bool value) {
    _isLoadingDocument = value;
    notifyListeners();
  }

  void _setSavingDocument(bool value) {
    _isSavingDocument = value;
    notifyListeners();
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
