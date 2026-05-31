import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/document_validity_status.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/datasources/driver_document_datasource.dart';
import '../../data/datasources/driver_license_category_datasource.dart';
import '../../data/models/driver_license_category_model.dart';
import '../../data/repositories/driver_document_repository_impl.dart';
import '../../data/repositories/driver_license_category_repository_impl.dart';
import '../stores/my_drivers_license_store.dart';

class MyDriversLicensePage extends StatefulWidget {
  final int? userId;

  const MyDriversLicensePage({super.key, this.userId});

  @override
  State<MyDriversLicensePage> createState() => _MyDriversLicensePageState();
}

class _MyDriversLicensePageState extends State<MyDriversLicensePage> {
  final TextEditingController _registrationController =
      TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _expirationDateController =
      TextEditingController();

  late final HttpService _httpService;
  late final DriverLicenseCategoryDatasource _categoryDatasource;
  late final DriverLicenseCategoryRepositoryImpl _categoryRepository;
  late final DriverDocumentDatasource _documentDatasource;
  late final DriverDocumentRepositoryImpl _documentRepository;
  late final MyselfService _myselfService;
  late final MyDriversLicenseStore _store;

  DateTime? _issueDate;
  DateTime? _expirationDate;
  bool _isEditing = true;
  bool _showUpdateButtonLabel = false;
  bool _expiredDialogShown = false;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _categoryDatasource = DriverLicenseCategoryDatasource(_httpService);
    _categoryRepository =
        DriverLicenseCategoryRepositoryImpl(_categoryDatasource);
    _documentDatasource = DriverDocumentDatasource(_httpService);
    _documentRepository = DriverDocumentRepositoryImpl(_documentDatasource);
    _myselfService = MyselfService();
    if (widget.userId != null) {
      _myselfService.currentUserId = widget.userId;
    }
    _store = MyDriversLicenseStore(
      _categoryRepository,
      _documentRepository,
      _myselfService,
      fallbackUserId: widget.userId,
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _store.dispose();
    _httpService.dispose();
    _registrationController.dispose();
    _issueDateController.dispose();
    _expirationDateController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _store.loadCategories(),
      _store.loadDriverDocument(),
    ]);

    if (!mounted) {
      return;
    }

    _fillFormFromStoredDocument();

    if (_store.loadDocumentError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_store.loadDocumentError!)),
      );
    }
  }

  void _fillFormFromStoredDocument() {
    final document = _store.driverDocument;
    if (document == null) {
      setState(() {
        _isEditing = true;
        _showUpdateButtonLabel = false;
      });
      return;
    }

    final issueDate = document.issueDateValue;
    final expirationDate = document.expirationDateValue;
    final status = _statusForExpirationDate(expirationDate);

    setState(() {
      _registrationController.text = document.licenseNumber;
      _issueDate = issueDate;
      _expirationDate = expirationDate;
      _issueDateController.text =
          issueDate == null ? '' : _formatDate(issueDate);
      _expirationDateController.text =
          expirationDate == null ? '' : _formatDate(expirationDate);
      _isEditing = status == DocumentValidityStatusEnum.needsInformation;
      _showUpdateButtonLabel = false;
    });

    if (status == DocumentValidityStatusEnum.expired && !_expiredDialogShown) {
      _expiredDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _showExpiredDocumentDialog();
      });
    }
  }

  Future<void> _selectIssueDate() async {
    if (!_isEditing) {
      return;
    }

    final selectedDate = await _showLicenseDatePicker(
      initialDate: _issueDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _issueDate = selectedDate;
      _issueDateController.text = _formatDate(selectedDate);
    });
  }

  Future<void> _selectExpirationDate() async {
    if (!_isEditing) {
      return;
    }

    final now = DateTime.now();
    final selectedDate = await _showLicenseDatePicker(
      initialDate: _expirationDate ?? DateTime(now.year + 5, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 30),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _expirationDate = selectedDate;
      _expirationDateController.text = _formatDate(selectedDate);
    });
  }

  Future<DateTime?> _showLicenseDatePicker({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: FretColors.loginFooterLink,
                  onPrimary: FretColors.white,
                  surface: FretColors.white,
                  onSurface: FretColors.neutral900,
                ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _saveDriversLicense() async {
    final wasUpdating = _store.hasDriverDocument;
    final success = await _store.saveDriverDocument(
      licenseNumber: _registrationController.text,
      issueDate: _issueDate,
      expirationDate: _expirationDate,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasUpdating
                ? 'CNH atualizada com sucesso.'
                : 'CNH cadastrada com sucesso.',
          ),
        ),
      );
      Navigator.of(context).maybePop();
      return;
    }

    final errorMessage =
        _store.saveDocumentError ?? 'Não foi possível salvar sua CNH.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  Future<void> _handleFooterAction() async {
    if (_isEditing || !_store.hasDriverDocument) {
      await _saveDriversLicense();
      return;
    }

    final status = _currentDocumentStatus;
    if (status == DocumentValidityStatusEnum.expired) {
      await _showExpiredDocumentDialog();
      return;
    }

    await _showChangeDataDialog(status);
  }

  Future<void> _showChangeDataDialog(DocumentValidityStatusEnum status) async {
    final subtitle = status == DocumentValidityStatusEnum.expiringSoon
        ? 'Seu documento vence em ${_daysUntilExpiration ?? 0} dias. Recomendamos que uma atualização seja realizada. Deseja alterar seus dados agora?'
        : 'Seu documento está dentro do prazo de validade, deseja alterar seus dados agora?';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alterar dados da CNH',
                  style: TextStyle(
                    color: FretColors.loginFooterLink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: FretColors.neutral700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FretColors.neutral200,
                            foregroundColor: FretColors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _isEditing = true;
                              _showUpdateButtonLabel = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FretColors.loginFooterLink,
                            foregroundColor: FretColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Alterar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showExpiredDocumentDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: FretColors.destructive500,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: FretColors.destructive600,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Documento vencido',
                                style: TextStyle(
                                  color: FretColors.destructive600,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Seu documento Carteira Nacional de Habilitação está com prazo de validade expirado. Atualize imediatamente para continuar suas entregas.',
                                style: TextStyle(
                                  color: FretColors.neutral700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _isEditing = true;
                            _showUpdateButtonLabel = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FretColors.loginFooterLink,
                          foregroundColor: FretColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Atualizar agora',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: FretColors.neutral500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DocumentValidityStatusEnum get _currentDocumentStatus {
    if (!_store.hasDriverDocument) {
      return DocumentValidityStatusEnum.needsInformation;
    }

    return _statusForExpirationDate(_expirationDate);
  }

  int? get _daysUntilExpiration {
    if (_expirationDate == null) {
      return null;
    }

    final today = _dateOnly(DateTime.now());
    final expirationDate = _dateOnly(_expirationDate!);

    return expirationDate.difference(today).inDays;
  }

  String get _footerButtonLabel {
    if (_store.isSavingDocument) {
      return 'Salvando...';
    }

    if (!_isEditing && _store.hasDriverDocument) {
      final status = _currentDocumentStatus;
      if (status == DocumentValidityStatusEnum.valid ||
          status == DocumentValidityStatusEnum.expiringSoon) {
        return 'Alterar meus dados';
      }
    }

    if (_showUpdateButtonLabel) {
      return 'Atualizar';
    }

    return 'Salvar';
  }

  DocumentValidityStatusEnum _statusForExpirationDate(DateTime? expiresAt) {
    if (expiresAt == null) {
      return DocumentValidityStatusEnum.needsInformation;
    }

    final today = _dateOnly(DateTime.now());
    final expirationDate = _dateOnly(expiresAt);
    final daysUntilExpiration = expirationDate.difference(today).inDays;

    if (daysUntilExpiration < 0) {
      return DocumentValidityStatusEnum.expired;
    }

    if (daysUntilExpiration < 30) {
      return DocumentValidityStatusEnum.expiringSoon;
    }

    return DocumentValidityStatusEnum.valid;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$month/$day/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final isLoadingInitialData =
            _store.isLoadingDocument || _store.isLoadingCategories;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          body: SafeArea(
            child: Column(
              children: [
                const _MyDriversLicenseHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                    children: [
                      const Text(
                        'Informações da Habilitação',
                        style: TextStyle(
                          color: FretColors.loginFooterLink,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Mantenha seus dados de condutor atualizados para receber alertas de vencimento',
                        style: TextStyle(
                          color: Color(0xFF6F727D),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DriversLicenseFormCard(
                        isReadOnly: !_isEditing || isLoadingInitialData,
                        isLoadingCategories: _store.isLoadingCategories,
                        categoriesError: _store.categoriesError,
                        categories: _store.categories,
                        selectedCategoryId: _store.selectedCategoryId,
                        registrationController: _registrationController,
                        issueDateController: _issueDateController,
                        expirationDateController: _expirationDateController,
                        onCategoryChanged: _store.selectCategory,
                        onReloadCategories: _store.loadCategories,
                        onIssueDateTap: _selectIssueDate,
                        onExpirationDateTap: _selectExpirationDate,
                      ),
                    ],
                  ),
                ),
                _SaveDriversLicenseFooter(
                  isSaving: _store.isSavingDocument,
                  isDisabled: isLoadingInitialData,
                  label: _footerButtonLabel,
                  onSave: _handleFooterAction,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MyDriversLicenseHeader extends StatelessWidget {
  const _MyDriversLicenseHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7E9F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: FretColors.loginFooterLink,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Minha CNH',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: FretColors.loginFooterLink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriversLicenseFormCard extends StatelessWidget {
  final bool isReadOnly;
  final bool isLoadingCategories;
  final String? categoriesError;
  final List<DriverLicenseCategoryModel> categories;
  final int? selectedCategoryId;
  final TextEditingController registrationController;
  final TextEditingController issueDateController;
  final TextEditingController expirationDateController;
  final ValueChanged<int?> onCategoryChanged;
  final VoidCallback onReloadCategories;
  final VoidCallback onIssueDateTap;
  final VoidCallback onExpirationDateTap;

  const _DriversLicenseFormCard({
    required this.isReadOnly,
    required this.isLoadingCategories,
    required this.categoriesError,
    required this.categories,
    required this.selectedCategoryId,
    required this.registrationController,
    required this.issueDateController,
    required this.expirationDateController,
    required this.onCategoryChanged,
    required this.onReloadCategories,
    required this.onIssueDateTap,
    required this.onExpirationDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F1A4A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DriversLicenseInputLabel(
            'Selecione a categoria da sua CNH',
          ),
          const SizedBox(height: 8),
          _DriversLicenseCategoryField(
            isReadOnly: isReadOnly,
            isLoading: isLoadingCategories,
            errorMessage: categoriesError,
            categories: categories,
            selectedCategoryId: selectedCategoryId,
            onChanged: onCategoryChanged,
            onRetry: onReloadCategories,
          ),
          const SizedBox(height: 12),
          const _DriversLicenseInputLabel('Nº de Registro'),
          const SizedBox(height: 8),
          _DriversLicenseTextField(
            isReadOnly: isReadOnly,
            controller: registrationController,
            hintText: 'Ex: 00000000000',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
          ),
          const SizedBox(height: 12),
          const _DriversLicenseInputLabel('Data de emissão'),
          const SizedBox(height: 8),
          _DriversLicenseDateField(
            isReadOnly: isReadOnly,
            controller: issueDateController,
            onTap: onIssueDateTap,
          ),
          const SizedBox(height: 12),
          const _DriversLicenseInputLabel('Data de validade'),
          const SizedBox(height: 8),
          _DriversLicenseDateField(
            isReadOnly: isReadOnly,
            controller: expirationDateController,
            onTap: onExpirationDateTap,
          ),
        ],
      ),
    );
  }
}

class _DriversLicenseInputLabel extends StatelessWidget {
  final String label;

  const _DriversLicenseInputLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: FretColors.loginFooterLink,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        height: 1.12,
      ),
    );
  }
}

class _DriversLicenseCategoryField extends StatelessWidget {
  final bool isReadOnly;
  final bool isLoading;
  final String? errorMessage;
  final List<DriverLicenseCategoryModel> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onChanged;
  final VoidCallback onRetry;

  const _DriversLicenseCategoryField({
    required this.isReadOnly,
    required this.isLoading,
    required this.errorMessage,
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelectedCategory = categories.any(
      (category) => category.id == selectedCategoryId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: FretColors.neutral200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: isLoading
              ? const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value:
                        hasSelectedCategory ? selectedCategoryId : null,
                    isExpanded: true,
                    icon: isReadOnly
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: FretColors.loginFooterLink,
                            size: 24,
                          ),
                    hint: Text(
                      categories.isEmpty
                          ? 'Nenhuma categoria encontrada'
                          : 'Selecionar categoria',
                      style: const TextStyle(
                        color: FretColors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    dropdownColor: FretColors.white,
                    borderRadius: BorderRadius.circular(12),
                    style: const TextStyle(
                      color: FretColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(
                          category.fullLabel,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: isReadOnly || categories.isEmpty
                        ? null
                        : onChanged,
                  ),
                ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: FretColors.destructive600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onRetry,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Tentar novamente',
                    style: TextStyle(
                      color: FretColors.loginFooterLink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DriversLicenseTextField extends StatelessWidget {
  final bool isReadOnly;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _DriversLicenseTextField({
    required this.isReadOnly,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly,
      enableInteractiveSelection: !isReadOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        color: FretColors.black,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFA7A9B1),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: FretColors.neutral200,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _DriversLicenseDateField extends StatelessWidget {
  final bool isReadOnly;
  final TextEditingController controller;
  final VoidCallback onTap;

  const _DriversLicenseDateField({
    required this.isReadOnly,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      enableInteractiveSelection: !isReadOnly,
      onTap: isReadOnly ? null : onTap,
      style: const TextStyle(
        color: FretColors.black,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: 'mm/dd/yyyy',
        hintStyle: const TextStyle(
          color: FretColors.black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: FretColors.neutral200,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        suffixIcon: const Padding(
          padding: EdgeInsets.only(right: 14),
          child: Icon(
            Icons.calendar_today_outlined,
            color: FretColors.black,
            size: 18,
          ),
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 0,
          minHeight: 0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SaveDriversLicenseFooter extends StatelessWidget {
  final bool isSaving;
  final bool isDisabled;
  final String label;
  final Future<void> Function() onSave;

  const _SaveDriversLicenseFooter({
    required this.isSaving,
    required this.isDisabled,
    required this.label,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        border: Border(
          top: BorderSide(color: Color(0xFFE7E9F0), width: 1),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [FretColors.loginButtonStart, FretColors.loginButtonEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: FretColors.loginButtonEnd.withOpacity(0.24),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isSaving
                || isDisabled
                ? null
                : () {
                    onSave();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: FretColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
