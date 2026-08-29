import 'package:flutter/foundation.dart';

class AppEnvironment {
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: '',
  );
  static const String apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String productionApiBaseUrl =
      'https://fretado-api.onrender.com';

  static String get apiBaseUrl {
    if (apiBaseUrlOverride.isNotEmpty) {
      return _normalizeBaseUrl(apiBaseUrlOverride);
    }

    if (kIsWeb) {
      return _resolveWebBaseUrl();
    }

    return productionApiBaseUrl;
  }

  static String get environmentName {
    if (appEnv.isNotEmpty) {
      return appEnv;
    }

    return _isLocalApi(apiBaseUrl) ? 'local' : 'production';
  }

  static bool get isProduction => environmentName == 'production';

  static String _resolveWebBaseUrl() {
    final Uri pageUri = Uri.base;
    final String host = pageUri.host;

    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      return 'http://localhost:8000';
    }

    if (_isLocalNetworkHost(host)) {
      return 'http://$host:8000';
    }

    return productionApiBaseUrl;
  }

  static String _normalizeBaseUrl(String value) {
    final String trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static bool _isLocalApi(String value) {
    final Uri? uri = Uri.tryParse(value);
    final String host = uri?.host ?? '';
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2' ||
        _isLocalNetworkHost(host);
  }

  static bool _isLocalNetworkHost(String host) {
    return host.startsWith('10.') ||
        host.startsWith('192.168.') ||
        RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(host);
  }
}
