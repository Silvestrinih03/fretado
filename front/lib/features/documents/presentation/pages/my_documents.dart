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
  Widget build(BuildContext context) => FretScreenTheme(
    child: AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final document = _DriverDocument(
          title: 'CNH',
          subtitle: 'Carteira Nacional de Habilitação',
          expiresAt: _store.driverDocument?.expirationDateValue,
        );
        return Scaffold(
          backgroundColor: FretColors.screenBackground,
          appBar: const FretSecondaryAppBar(title: 'Meus documentos'),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              children: [
                const Text(
                  'Gerencie sua documentação profissional',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: FretColors.screenMuted,
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
                  if (_store.errorMessage == null) ...[
                    const SizedBox(height: 14),
                    _DocumentHint(status: document.status),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _DocumentStatusCard extends StatelessWidget {
  final _DriverDocument document;
  final VoidCallback onTap;
  const _DocumentStatusCard({required this.document, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = document.status;
    final pending = status == DocumentValidityStatusEnum.needsInformation;
    final color = pending ? const Color(0xFF9A7810) : status.iconColor;
    return Material(
      color: FretColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: pending ? FretColors.screenGold : status.borderColor,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const FretIconBox(
                icon: Icons.credit_card_outlined,
                size: 48,
                radius: 15,
                iconSize: 23,
                backgroundColor: FretColors.screenBackground,
                iconColor: FretColors.screenDark,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      document.subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: FretColors.screenMuted,
                      ),
                    ),
                    if (document.statusMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        document.statusMessage!,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FretIconBox(
                icon: pending ? Icons.edit_outlined : status.icon,
                size: 40,
                radius: 12,
                backgroundColor: status.iconBackgroundColor,
                iconColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentHint extends StatelessWidget {
  final DocumentValidityStatusEnum status;
  const _DocumentHint({required this.status});

  @override
  Widget build(BuildContext context) {
    final pending = status == DocumentValidityStatusEnum.needsInformation;
    final text = switch (status) {
      DocumentValidityStatusEnum.needsInformation =>
        'Complete sua CNH para manter o perfil apto a receber novas corridas.',
      DocumentValidityStatusEnum.valid =>
        'CNH cadastrada. Mantenha seus dados de condutor atualizados.',
      DocumentValidityStatusEnum.expiringSoon =>
        'Sua CNH está próxima do vencimento. Confira a validade e mantenha seus dados atualizados.',
      DocumentValidityStatusEnum.expired =>
        'Sua CNH está vencida. Atualize a documentação para receber novas corridas.',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: pending
            ? FretColors.screenGold.withValues(alpha: .08)
            : status.iconBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          height: 1.5,
          color: pending ? const Color(0xFF806515) : status.iconColor,
        ),
      ),
    );
  }
}

class _DocumentsErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DocumentsErrorCard({required this.message, required this.onRetry});

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
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
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
      DocumentValidityStatusEnum.valid =>
        'Documento válido até ${expiresAt!.day.toString().padLeft(2, '0')}/${expiresAt!.month.toString().padLeft(2, '0')}/${expiresAt!.year}',
      DocumentValidityStatusEnum.expiringSoon =>
        'Vence em ${daysUntilExpiration ?? 0} dias',
      DocumentValidityStatusEnum.expired => 'Vencido. Envie novamente',
    };
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
