import 'package:flutter/material.dart';

import '../theme/fret_colors.dart';
import 'fret_feedback.dart';

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
}) {
  final confirmation = _FretRideProgressConfirmation.fromStatusId(statusId);
  if (confirmation == null) {
    return Future<bool>.value(true);
  }

  return showFretConfirmationPopup(
    context,
    title: confirmation.title,
    message: confirmation.message,
    confirmLabel: confirmation.confirmLabel,
    icon: confirmation.icon,
    accentColor: confirmation.accentColor,
  );
}

class _FretRideProgressConfirmation {
  final String title;
  final String message;
  final String confirmLabel;
  final IconData icon;
  final Color accentColor;

  const _FretRideProgressConfirmation({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.icon,
    required this.accentColor,
  });

  static _FretRideProgressConfirmation? fromStatusId(int statusId) {
    return switch (statusId) {
      2 => const _FretRideProgressConfirmation(
        title: 'Iniciar corrida?',
        message: 'Confirme que voce esta pronto para iniciar esta corrida.',
        confirmLabel: 'Iniciar',
        icon: Icons.play_arrow_rounded,
        accentColor: FretColors.attention800,
      ),
      3 => const _FretRideProgressConfirmation(
        title: 'Confirmar coleta?',
        message: 'Confirme que o pacote foi coletado com sucesso.',
        confirmLabel: 'Confirmar',
        icon: Icons.inventory_2_outlined,
        accentColor: Color(0xFF9F3F00),
      ),
      4 => const _FretRideProgressConfirmation(
        title: 'Finalizar entrega?',
        message: 'Confirme que a entrega foi concluida com sucesso.',
        confirmLabel: 'Finalizar',
        icon: Icons.flag_outlined,
        accentColor: Color(0xFF5B2AA4),
      ),
      _ => null,
    };
  }
}
