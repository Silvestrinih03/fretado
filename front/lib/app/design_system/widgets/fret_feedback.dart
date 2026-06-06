import 'package:flutter/material.dart';

import '../theme/fret_colors.dart';

void showFretErrorPopup(
  BuildContext context, {
  required String message,
  String title = 'Nao foi possivel continuar',
  String buttonLabel = 'Entendi',
}) {
  final String trimmedMessage = message.trim();

  ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return _FretErrorDialog(
        title: title,
        message: trimmedMessage.isEmpty
            ? 'Ocorreu um erro inesperado.'
            : trimmedMessage,
        buttonLabel: buttonLabel,
      );
    },
  );
}

class _FretErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;

  const _FretErrorDialog({
    required this.title,
    required this.message,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FretColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FretColors.destructive100),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: FretColors.destructive050,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: FretColors.destructive600,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: FretColors.neutral900,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message,
                            style: const TextStyle(
                              color: FretColors.neutral700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Fechar',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: FretColors.neutral500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 46,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: FretColors.loginFooterLink,
                      foregroundColor: FretColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
