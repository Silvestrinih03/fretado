import 'package:flutter/material.dart';

import '../theme/fret_colors.dart';

class FretRideStatusBadge extends StatelessWidget {
  final int statusId;
  final String? fallbackLabel;
  final bool dense;

  const FretRideStatusBadge({
    super.key,
    required this.statusId,
    this.fallbackLabel,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = FretRideStatusStyle.fromStatusId(
      statusId,
      fallbackLabel: fallbackLabel,
    );

    return Container(
      constraints: BoxConstraints(minHeight: dense ? 28 : 32),
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.borderColor),
      ),
      child: Text(
        style.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: style.foregroundColor,
          fontSize: dense ? 10 : 11,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}

class FretRideStatusStyle {
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;

  const FretRideStatusStyle({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
  });

  static FretRideStatusStyle fromStatusId(
    int statusId, {
    String? fallbackLabel,
  }) {
    final String normalizedFallback = fallbackLabel?.trim() ?? '';

    return switch (statusId) {
      1 => const FretRideStatusStyle(
        label: 'Aguardando aceite',
        backgroundColor: Color(0xFFE8F3FF),
        borderColor: Color(0xFFB8DBFF),
        foregroundColor: Color(0xFF155A94),
      ),
      2 => const FretRideStatusStyle(
        label: 'Aguardando inicio',
        backgroundColor: FretColors.attention100,
        borderColor: FretColors.attention300,
        foregroundColor: FretColors.attention900,
      ),
      3 => const FretRideStatusStyle(
        label: 'A caminho da coleta',
        backgroundColor: Color(0xFFFFEFE1),
        borderColor: Color(0xFFFFC28A),
        foregroundColor: Color(0xFF9F3F00),
      ),
      4 => const FretRideStatusStyle(
        label: 'A caminho da entrega',
        backgroundColor: Color(0xFFF0E9FF),
        borderColor: Color(0xFFD7C5FF),
        foregroundColor: Color(0xFF5B2AA4),
      ),
      5 => const FretRideStatusStyle(
        label: 'Corrida finalizada',
        backgroundColor: FretColors.success100,
        borderColor: FretColors.success300,
        foregroundColor: FretColors.success800,
      ),
      6 => const FretRideStatusStyle(
        label: 'Corrida cancelada',
        backgroundColor: FretColors.destructive100,
        borderColor: FretColors.destructive300,
        foregroundColor: FretColors.destructive700,
      ),
      7 => const FretRideStatusStyle(
        label: 'Nao atendida',
        backgroundColor: FretColors.neutral100,
        borderColor: FretColors.neutral300,
        foregroundColor: FretColors.neutral700,
      ),
      _ => FretRideStatusStyle(
        label: normalizedFallback.isNotEmpty
            ? normalizedFallback
            : 'Status $statusId',
        backgroundColor: FretColors.neutral100,
        borderColor: FretColors.neutral300,
        foregroundColor: FretColors.neutral700,
      ),
    };
  }
}

Future<bool> showFretRideProgressConfirmation(
  BuildContext context, {
  required int statusId,
  bool isCancellationReturn = false,
}) async {
  final confirmation = _FretRideProgressConfirmation.fromStatusId(
    statusId,
    isCancellationReturn: isCancellationReturn,
  );
  if (confirmation == null) {
    return true;
  }

  final result = await showDialog<bool>(
    context: context,
    barrierColor: FretColors.brandBlack.withValues(alpha: 0.48),
    builder: (_) => _FretRideProgressDialog(confirmation: confirmation),
  );
  return result ?? false;
}

class _FretRideProgressConfirmation {
  final int step;
  final String stage;
  final String title;
  final String message;
  final String confirmLabel;
  final IconData icon;

  const _FretRideProgressConfirmation({
    required this.step,
    required this.stage,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.icon,
  });

  static _FretRideProgressConfirmation? fromStatusId(
    int statusId, {
    required bool isCancellationReturn,
  }) {
    return switch (statusId) {
      2 => const _FretRideProgressConfirmation(
        step: 1,
        stage: 'INÍCIO DA CORRIDA',
        title: 'Iniciar corrida?',
        message:
            'Tudo pronto para seguir até a coleta? Ao confirmar, a corrida será marcada como iniciada.',
        confirmLabel: 'Iniciar corrida',
        icon: Icons.play_arrow_rounded,
      ),
      3 => const _FretRideProgressConfirmation(
        step: 2,
        stage: 'COLETA',
        title: 'Confirmar coleta?',
        message:
            'Confira se a encomenda já está com você e pronta para o transporte. A próxima etapa será a entrega.',
        confirmLabel: 'Confirmar coleta',
        icon: Icons.inventory_2_outlined,
      ),
      4 => _FretRideProgressConfirmation(
        step: 3,
        stage: isCancellationReturn ? 'DEVOLUÇÃO' : 'ENTREGA',
        title: isCancellationReturn
            ? 'Confirmar devolução?'
            : 'Confirmar entrega?',
        message: isCancellationReturn
            ? 'Confirme somente após devolver a encomenda no destino combinado. Esta ação registra a devolução e finaliza a corrida.'
            : 'Confirme somente após entregar a encomenda ao destinatário. Esta ação registra a entrega e finaliza a corrida.',
        confirmLabel: isCancellationReturn
            ? 'Finalizar devolução'
            : 'Finalizar corrida',
        icon: Icons.flag_outlined,
      ),
      _ => null,
    };
  }
}

class _FretRideProgressDialog extends StatelessWidget {
  final _FretRideProgressConfirmation confirmation;

  const _FretRideProgressDialog({required this.confirmation});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: FretColors.appSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: FretColors.appBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: FretColors.brandGoldSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      confirmation.icon,
                      color: FretColors.brandGoldDark,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(false),
                    style: IconButton.styleFrom(
                      backgroundColor: FretColors.appBackground,
                      foregroundColor: FretColors.neutral600,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '${confirmation.stage} · ETAPA ${confirmation.step} DE 3',
                style: const TextStyle(
                  color: FretColors.brandGoldDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                confirmation.title,
                style: const TextStyle(
                  color: FretColors.brandGraphite,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                confirmation.message,
                style: const TextStyle(
                  color: FretColors.neutral600,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: FretColors.brandGraphite,
                  foregroundColor: FretColors.white,
                  minimumSize: const Size.fromHeight(52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(
                  Icons.check_rounded,
                  color: FretColors.brandGold,
                  size: 20,
                ),
                label: Text(
                  confirmation.confirmLabel,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FretColors.brandGraphite,
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.all(14),
                  side: const BorderSide(color: FretColors.appBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Voltar', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
