import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/design_system/design_system.dart';

/// Visible wherever address lookup results are shown or reused.
class GeocodingCredit extends StatelessWidget {
  final String? source;
  const GeocodingCredit({super.key, this.source});

  static const _style = TextStyle(
    fontSize: 11,
    color: FretColors.textSecondary,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  Future<void> _open(BuildContext context, String url) async {
    try {
      if (await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      /* Explain a missing external browser without breaking the map. */
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir os créditos. Tente novamente.'),
        ),
      );
    }
  }

  Widget _link(BuildContext context, String label, String url) => TextButton(
    onPressed: () => _open(context, url),
    style: TextButton.styleFrom(
      foregroundColor: FretColors.textSecondary,
      textStyle: _style,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(vertical: 4),
    ),
    child: Text(label, style: _style),
  );

  @override
  Widget build(BuildContext context) {
    final credits = (source ?? '')
        .split('|')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (credits.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 3),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        children: [
          _link(context, 'Powered by Geoapify', 'https://www.geoapify.com/'),
          _link(
            context,
            '© OpenStreetMap contributors',
            'https://www.openstreetmap.org/copyright',
          ),
          for (final credit in credits)
            if (credit != 'Powered by Geoapify' &&
                credit != '© OpenStreetMap contributors')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(credit, style: _style),
              ),
        ],
      ),
    );
  }
}
