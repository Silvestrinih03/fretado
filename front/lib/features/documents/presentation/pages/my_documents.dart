import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/document_validity_status.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/services/myself_service.dart';
import '../../data/datasources/driver_document_datasource.dart';
import '../../data/repositories/driver_document_repository_impl.dart';
import '../stores/my_documents_store.dart';
import 'my_drivers_license.dart';

class MyDocumentsPage extends StatefulWidget {
  final int? userId;

  const MyDocumentsPage({super.key, this.userId});

  @override
  State<MyDocumentsPage> createState() => _MyDocumentsPageState();
}

class _MyDocumentsPageState extends State<MyDocumentsPage> {
  late final HttpService _httpService;
  late final DriverDocumentDatasource _documentDatasource;
  late final DriverDocumentRepositoryImpl _documentRepository;
  late final MyselfService _myselfService;
  late final MyDocumentsStore _store;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _documentDatasource = DriverDocumentDatasource(_httpService);
    _documentRepository = DriverDocumentRepositoryImpl(_documentDatasource);
    _myselfService = MyselfService();
    if (widget.userId != null) {
      _myselfService.currentUserId = widget.userId;
    }
    _store = MyDocumentsStore(
      _documentRepository,
      _myselfService,
      fallbackUserId: widget.userId,
    );
    _store.loadDriverDocument();
  }

  @override
  void dispose() {
    _store.dispose();
    _httpService.dispose();
    super.dispose();
  }

  Future<void> _openDriversLicensePage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MyDriversLicensePage(userId: widget.userId),
      ),
    );

    if (!mounted) {
      return;
    }

    _store.loadDriverDocument();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final document = _DriverDocument(
          title: 'CNH',
          subtitle: 'Carteira Nacional de Habilitação',
          expiresAt: _store.driverDocument?.expirationDateValue,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _MyDocumentsHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    children: [
                      const Text(
                        'Gerencie sua documentação profissional',
                        style: TextStyle(
                          color: Color(0xFF777A86),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_store.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else ...[
                        if (_store.errorMessage != null) ...[
                          _DocumentsErrorCard(
                            message: _store.errorMessage!,
                            onRetry: _store.loadDriverDocument,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _DocumentStatusCard(
                          document: document,
                          onTap: _openDriversLicensePage,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MyDocumentsHeader extends StatelessWidget {
  const _MyDocumentsHeader();

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
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Meus documentos',
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

class _DocumentStatusCard extends StatelessWidget {
  final _DriverDocument document;
  final VoidCallback onTap;

  const _DocumentStatusCard({
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = document.status;
    final statusMessage = document.statusMessage;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 430;
        final cardPadding = isCompact ? 14.0 : 18.0;
        final leadingSize = isCompact ? 44.0 : 54.0;
        final leadingIconSize = isCompact ? 24.0 : 28.0;
        final titleFontSize = isCompact ? 17.0 : 20.0;
        final subtitleFontSize = isCompact ? 13.0 : 15.0;
        final statusMessageFontSize = isCompact ? 12.0 : 13.0;
        final statusSize = isCompact ? 36.0 : 42.0;
        final contentGap = isCompact ? 10.0 : 14.0;
        final statusGap = isCompact ? 8.0 : 10.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: FretColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: status.borderColor,
                  width: 1.4,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080F1A4A),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: leadingSize,
                    height: leadingSize,
                    decoration: BoxDecoration(
                      color: FretColors.neutral100,
                      borderRadius:
                          BorderRadius.circular(isCompact ? 14.0 : 18.0),
                    ),
                    child: Icon(
                      Icons.credit_card_rounded,
                      color: FretColors.loginFooterLink,
                      size: leadingIconSize,
                    ),
                  ),
                  SizedBox(width: contentGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w800,
                            color: FretColors.loginFooterLink,
                            height: 1,
                          ),
                        ),
                          const SizedBox(height: 4),
                        Text(
                          document.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF2F3342),
                            height: 1.12,
                          ),
                        ),
                        if (statusMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            statusMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: status.iconColor,
                              fontSize: statusMessageFontSize,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: statusGap),
                  Container(
                    width: statusSize,
                    height: statusSize,
                    decoration: BoxDecoration(
                      color: status.iconBackgroundColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      status.icon,
                      color: status.iconColor,
                      size: isCompact ? 22.0 : 24.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DocumentsErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DocumentsErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FretColors.destructive200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: FretColors.destructive600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: FretColors.neutral700,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _DriverDocument {
  final String title;
  final String subtitle;
  final DateTime? expiresAt;

  const _DriverDocument({
    required this.title,
    required this.subtitle,
    required this.expiresAt,
  });

  DocumentValidityStatusEnum get status {
    final days = daysUntilExpiration;

    if (days == null) {
      return DocumentValidityStatusEnum.needsInformation;
    }

    if (days < 0) {
      return DocumentValidityStatusEnum.expired;
    }

    if (days < 30) {
      return DocumentValidityStatusEnum.expiringSoon;
    }

    return DocumentValidityStatusEnum.valid;
  }

  int? get daysUntilExpiration {
    if (expiresAt == null) {
      return null;
    }

    final today = _dateOnly(DateTime.now());
    final expirationDate = _dateOnly(expiresAt!);

    return expirationDate.difference(today).inDays;
  }

  String? get statusMessage {
    return switch (status) {
      DocumentValidityStatusEnum.needsInformation =>
        'Preenchimento obrigatório',
      DocumentValidityStatusEnum.valid => null,
      DocumentValidityStatusEnum.expiringSoon =>
        'Vence em ${daysUntilExpiration ?? 0} dias',
      DocumentValidityStatusEnum.expired => 'Vencido. Envie novamente',
    };
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
