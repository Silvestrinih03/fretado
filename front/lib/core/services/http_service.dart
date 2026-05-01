import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HttpService {
  final String baseUrl;
  final http.Client _client;

  HttpService({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? _resolveBaseUrl(),
      _client = client ?? http.Client();

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${_normalizePath(path)}');

    final http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json', ...?headers},
        body: jsonEncode(body ?? <String, dynamic>{}),
      );
    } catch (e) {
      throw HttpServiceException(
        message:
            'Não foi possível conectar ao servidor em $baseUrl. '
            'Verifique se a API está rodando e se a URL está correta para o seu dispositivo. '
            'Detalhe: $e',
      );
    }

    final Map<String, dynamic> parsedData = _parseResponseBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parsedData;
    }

    throw HttpServiceException(
      message: _extractErrorMessage(parsedData),
      statusCode: response.statusCode,
      data: parsedData,
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${_normalizePath(path)}');

    final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json', ...?headers},
      );
    } catch (e) {
      throw HttpServiceException(
        message:
            'Não foi possível conectar ao servidor em $baseUrl. '
            'Verifique se a API está rodando e se a URL está correta para o seu dispositivo. '
            'Detalhe: $e',
      );
    }

    final Map<String, dynamic> parsedData = _parseResponseBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parsedData;
    }

    throw HttpServiceException(
      message: _extractErrorMessage(parsedData),
      statusCode: response.statusCode,
      data: parsedData,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${_normalizePath(path)}');

    final http.Response response;
    try {
      response = await _client.patch(
        uri,
        headers: {'Content-Type': 'application/json', ...?headers},
        body: jsonEncode(body ?? <String, dynamic>{}),
      );
    } catch (e) {
      throw HttpServiceException(
        message:
            'NÃ£o foi possÃ­vel conectar ao servidor em $baseUrl. '
            'Verifique se a API estÃ¡ rodando e se a URL estÃ¡ correta para o seu dispositivo. '
            'Detalhe: $e',
      );
    }

    final Map<String, dynamic> parsedData = _parseResponseBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parsedData;
    }

    throw HttpServiceException(
      message: _extractErrorMessage(parsedData),
      statusCode: response.statusCode,
      data: parsedData,
    );
  }

  static String _normalizePath(String path) {
    if (path.startsWith('/')) {
      return path;
    }
    return '/$path';
  }

  static Map<String, dynamic> _parseResponseBody(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{'data': decoded};
  }

  static String _extractErrorMessage(Map<String, dynamic> data) {
    final dynamic detail = data['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }

    final dynamic message = data['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    return 'Ocorreu um erro inesperado.';
  }

  static String _resolveBaseUrl() {
    const String envBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://localhost:8000';
  }

  void dispose() {
    _client.close();
  }
}

class HttpServiceException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  const HttpServiceException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'HttpServiceException($statusCode): $message';
}
