import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Visible wherever address lookup results are shown or reused.
class GeocodingCredit extends StatelessWidget {
  final String? source;
  const GeocodingCredit({super.key, this.source});

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    children: [
      TextButton(
        onPressed: () => launchUrl(
          Uri.parse('https://www.geoapify.com/'),
          mode: LaunchMode.externalApplication,
        ),
        child: const Text(
          'Powered by Geoapify',
          style: TextStyle(fontSize: 10),
        ),
      ),
      TextButton(
        onPressed: () => launchUrl(
          Uri.parse('https://www.openstreetmap.org/copyright'),
          mode: LaunchMode.externalApplication,
        ),
        child: const Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 10),
        ),
      ),
      for (final credit
          in (source ?? '').split('|').map((value) => value.trim()).toSet())
        if (credit.isNotEmpty &&
            credit != 'Powered by Geoapify' &&
            credit != '© OpenStreetMap contributors')
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(credit, style: const TextStyle(fontSize: 10)),
          ),
    ],
  );
}
