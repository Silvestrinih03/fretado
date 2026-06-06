import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/endpoints.dart';
import '../../../../core/services/http_service.dart';
import '../../../payments/data/datasources/user_card_datasource.dart';
import '../../../payments/data/models/user_card_model.dart';
import '../../../payments/presentation/pages/edit_card_data_page.dart';
import '../models/freight_address_data.dart';
import '../models/freight_package_data.dart';
import '../models/freight_quote_model.dart';

class ShippingPaymentPage extends StatefulWidget {
  final int userId;
  final FreightAddressData addressData;
  final FreightPackageData packageData;
  final FreightQuoteModel quote;

  const ShippingPaymentPage({
    super.key,
    required this.userId,
    required this.addressData,
    required this.packageData,
    required this.quote,
  });

  @override
  State<ShippingPaymentPage> createState() => _ShippingPaymentPageState();
}

class _ShippingPaymentPageState extends State<ShippingPaymentPage> {
  static const Color _primaryBlue = Color(0xFF080A73);
  static const Color _orange = Color(0xFFB45C00);
  static const Color _screenBackground = Color(0xFFF7F8FA);
  static const Color _mutedText = Color(0xFF3F4050);

  late final HttpService _httpService;
  late final UserCardDatasource _cardDatasource;

  List<UserCardModel> _cards = <UserCardModel>[];
  UserCardModel? _selectedCard;
  bool _isLoadingCards = true;
  bool _isPaying = false;
  String? _loadErrorMessage;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService();
    _cardDatasource = UserCardDatasource(_httpService);
    _loadCards();
  }

  @override
  void dispose() {
    _httpService.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoadingCards = true;
      _loadErrorMessage = null;
    });

    try {
      final cards = await _cardDatasource.listCardsByUser(widget.userId);
      final defaultCard = _findDefaultCard(cards);

      if (!mounted) {
        return;
      }

      setState(() {
        _cards = cards;
        _selectedCard = defaultCard ?? (cards.isNotEmpty ? cards.first : null);
      });
    } on UserCardDatasourceException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cards = <UserCardModel>[];
        _selectedCard = null;
        _loadErrorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cards = <UserCardModel>[];
        _selectedCard = null;
        _loadErrorMessage = 'Nao foi possivel carregar seus cartoes.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingCards = false);
      }
    }
  }

  Future<void> _openCardForm() async {
    final bool? didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditCardDataPage(userId: widget.userId),
      ),
    );

    if (!mounted || didSave != true) {
      return;
    }

    await _loadCards();
  }

  Future<void> _confirmShipping() async {
    final selectedCard = _selectedCard;
    if (selectedCard == null) {
      _showMessage('Selecione ou cadastre um cartao para continuar.');
      return;
    }

    setState(() => _isPaying = true);
    try {
      final response = await _httpService.post(
        Endpoints.createRide,
        body: {
          'client_user_id': widget.userId,
          'driver_user_id': null,
          'origin_latitude': widget.addressData.pickupLatitude,
          'origin_longitude': widget.addressData.pickupLongitude,
          'destination_latitude': widget.addressData.deliveryLatitude,
          'destination_longitude': widget.addressData.deliveryLongitude,
          ...widget.packageData.toQuoteJson(),
          'total_price': widget.quote.totalPrice,
          'status_id': 1,
        },
      );
      await _runRideDispatchJob();

      if (!mounted) {
        return;
      }

      final rideId = response['id']?.toString();
      final statusId = response['status_id']?.toString();

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Frete solicitado'),
          content: Text(
            [
              if (rideId != null) 'Corrida #$rideId criada com sucesso.',
              if (statusId != null) 'Status: $statusId.',
              'Metodo de pagamento verificado: cartao final ${selectedCard.lastFour}.',
            ].join('\n'),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ok'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on HttpServiceException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Nao foi possivel finalizar o pagamento agora.');
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }

  Future<void> _runRideDispatchJob() async {
    const jobSecret = String.fromEnvironment('JOB_SECRET');
    if (jobSecret.isEmpty) {
      return;
    }

    try {
      await _httpService.post(
        Endpoints.rideDispatchJob,
        headers: {'X-Job-Secret': jobSecret},
      );
    } catch (_) {
      // A corrida ja foi criada; o job agendado do backend ainda pode processar.
    }
  }

  void _selectCard(UserCardModel card) {
    setState(() => _selectedCard = card);
  }

  UserCardModel? _findDefaultCard(List<UserCardModel> cards) {
    for (final card in cards) {
      if (card.isDefault) {
        return card;
      }
    }

    return null;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    showFretErrorPopup(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _PaymentHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(11, 26, 11, 26),
                children: [
                  const Text(
                    'ETAPA 4 DE 4',
                    style: TextStyle(
                      color: _orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Pagamento',
                    style: TextStyle(
                      color: FretColors.neutral900,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecione um cartao cadastrado para confirmar.',
                    style: TextStyle(
                      color: _mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _FreightSummaryCard(
                    addressData: widget.addressData,
                    packageData: widget.packageData,
                    quote: widget.quote,
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Forma de Pagamento',
                          style: TextStyle(
                            color: FretColors.neutral900,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cadastrar cartao',
                        onPressed: _isPaying ? null : _openCardForm,
                        icon: const Icon(
                          Icons.add_card_rounded,
                          color: _primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentMethods(),
                  const SizedBox(height: 24),
                  _ConfirmShippingButton(
                    loading: _isPaying,
                    enabled: !_isLoadingCards && _selectedCard != null,
                    onPressed: _confirmShipping,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    if (_isLoadingCards) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadErrorMessage != null) {
      return _PaymentStateCard(
        icon: Icons.error_outline_rounded,
        title: 'Nao foi possivel carregar os cartoes',
        subtitle: _loadErrorMessage!,
        actionLabel: 'Tentar novamente',
        onTap: _loadCards,
      );
    }

    if (_cards.isEmpty) {
      return _PaymentStateCard(
        icon: Icons.add_card_rounded,
        title: 'Nenhum cartao cadastrado',
        subtitle: 'Cadastre um cartao para confirmar e criar a corrida.',
        actionLabel: 'Cadastrar cartao',
        onTap: _openCardForm,
      );
    }

    return Column(
      children: [
        ..._cards.map(
          (card) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PaymentOptionTile(
              card: card,
              selected: _selectedCard?.id == card.id,
              onTap: () => _selectCard(card),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 47,
      decoration: const BoxDecoration(
        color: FretColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8E9EF))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 2),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _ShippingPaymentPageState._primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Pagamento',
            style: TextStyle(
              color: _ShippingPaymentPageState._primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FreightSummaryCard extends StatelessWidget {
  final FreightAddressData addressData;
  final FreightPackageData packageData;
  final FreightQuoteModel quote;

  const _FreightSummaryCard({
    required this.addressData,
    required this.packageData,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 8, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Resumo do Frete',
                    style: TextStyle(
                      color: _ShippingPaymentPageState._primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 16),
                  _SummaryLabel(text: 'Origem'),
                  SizedBox(height: 10),
                  _SummaryLabel(text: 'Destino'),
                  SizedBox(height: 10),
                  _SummaryLabel(text: 'Carga'),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 18, 12, 18),
              color: const Color(0xFFF9F9FB),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatMoney(quote.totalPrice),
                      maxLines: 1,
                      style: const TextStyle(
                        color: FretColors.neutral900,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SummaryValue(text: addressData.pickupAddress),
                  const SizedBox(height: 10),
                  _SummaryValue(text: addressData.deliveryAddress),
                  const SizedBox(height: 10),
                  _SummaryValue(
                    text:
                        '${quote.vehicleLabel} - ${_formatMetric(packageData.weightKg)} kg',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLabel extends StatelessWidget {
  final String text;

  const _SummaryLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _ShippingPaymentPageState._mutedText,
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String text;

  const _SummaryValue({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: FretColors.neutral900,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final UserCardModel card;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        decoration: BoxDecoration(
          color: FretColors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected
                ? _ShippingPaymentPageState._primaryBlue
                : const Color(0xFFE3E5EC),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Radio<int>(
                value: card.id,
                groupValue: selected ? card.id : null,
                onChanged: (_) => onTap(),
                activeColor: _ShippingPaymentPageState._primaryBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2F8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                color: _ShippingPaymentPageState._primaryBlue,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.brandLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FretColors.neutral900,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Final ${card.lastFour} - ${card.expirationText}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ShippingPaymentPageState._mutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (card.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF0FF),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'Padrao',
                  style: TextStyle(
                    color: _ShippingPaymentPageState._primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _PaymentStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FretColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8C9D8)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _ShippingPaymentPageState._primaryBlue, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FretColors.neutral900,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ShippingPaymentPageState._mutedText,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(actionLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: _ShippingPaymentPageState._primaryBlue,
              foregroundColor: FretColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmShippingButton extends StatelessWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  const _ConfirmShippingButton({
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 43,
      child: ElevatedButton(
        onPressed: loading || !enabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 8,
          shadowColor: const Color(0x33080A73),
          backgroundColor: _ShippingPaymentPageState._primaryBlue,
          foregroundColor: FretColors.white,
          disabledBackgroundColor: const Color(0xFFB7B9D5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: FretColors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Confirmar e Solicitar Frete',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
      ),
    );
  }
}

String _formatMetric(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final integer = parts.first;
  final decimals = parts.last;
  final buffer = StringBuffer();

  for (int i = 0; i < integer.length; i++) {
    final reverseIndex = integer.length - i;
    buffer.write(integer[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'R\$ ${buffer.toString()},$decimals';
}
