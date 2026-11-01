import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_environment.dart';
import '../navigation/app_navigator.dart';
import 'session/session_storage.dart';

class HttpService {
  final String baseUrl;
  final http.Client _client;

  HttpService({String? baseUrl, http.Client? client})
    : baseUrl = _normalizeBaseUrl(baseUrl ?? AppEnvironment.apiBaseUrl),
      _client = client ?? http.Client();

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${_normalizePath(path)}');

    final requestHeaders = await _jsonHeaders(headers, authenticated);
    final http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: requestHeaders,
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

    await _handleAuthFailure(response.statusCode, authenticated);

    throw HttpServiceException(
      message: _extractErrorMessage(parsedData),
      statusCode: response.statusCode,
      data: parsedData,
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${_normalizePath(path)}');

    final requestHeaders = await _jsonHeaders(headers, authenticated);
    final http.Response response;
    try {
      response = await _client.get(uri, headers: requestHeaders);
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

    await _handleAuthFailure(response.statusCode, authenticated);

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
    bool authenticated = true,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${_normalizePath(path)}');

    final requestHeaders = await _jsonHeaders(headers, authenticated);
    final http.Response response;
    try {
      response = await _client.patch(
        uri,
        headers: requestHeaders,
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

    await _handleAuthFailure(response.statusCode, authenticated);

    throw HttpServiceException(
      message: _extractErrorMessage(parsedData),
      statusCode: response.statusCode,
      data: parsedData,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${_normalizePath(path)}');

    final requestHeaders = await _jsonHeaders(headers, authenticated);
    final http.Response response;
    try {
      response = await _client.put(
        uri,
        headers: requestHeaders,
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

    await _handleAuthFailure(response.statusCode, authenticated);

    throw HttpServiceException(
      message: _extractErrorMessage(parsedData),
      statusCode: response.statusCode,
      data: parsedData,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    final Uri uri = Uri.parse('$baseUrl${_normalizePath(path)}');

    final requestHeaders = await _jsonHeaders(headers, authenticated);
    final http.Response response;
    try {
      response = await _client.delete(
        uri,
        headers: requestHeaders,
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

    await _handleAuthFailure(response.statusCode, authenticated);

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

  Future<Map<String, dynamic>> putMultipart(
    String path, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl${_normalizePath(path)}'),
    );
    final token = await _savedAccessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      ),
    );
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 60)),
      ).timeout(const Duration(seconds: 60));
    } catch (_) {
      throw const HttpServiceException(
        message:
            'Não foi possível enviar a foto. Verifique sua conexão e tente novamente.',
      );
    }
    final Map<String, dynamic> data;
    try {
      data = _parseResponseBody(response.body);
    } on FormatException {
      await _handleAuthFailure(response.statusCode, true);
      throw HttpServiceException(
        message: 'O servidor não conseguiu processar a foto. Tente novamente.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    await _handleAuthFailure(response.statusCode, true);
    throw HttpServiceException(
      message: _extractErrorMessage(data),
      statusCode: response.statusCode,
      data: data,
    );
  }

  static Future<Map<String, String>> _jsonHeaders(
    Map<String, String>? headers,
    bool authenticated,
  ) async {
    final String? accessToken = authenticated
        ? await _savedAccessToken()
        : null;
    return {
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
      ...?headers,
    };
  }

  static Future<String?> _savedAccessToken() async {
    final sessionStorage = SessionStorage.instance;
    await sessionStorage.loadSavedSession();
    return sessionStorage.currentAccessToken;
  }

  static Future<void> _handleAuthFailure(
    int statusCode,
    bool authenticated,
  ) async {
    if (!authenticated || statusCode != 401) {
      return;
    }

    await SessionStorage.instance.clearSession();
    redirectToLogin();
  }

  static String _normalizeBaseUrl(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
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
    if (detail is Map && detail['message'] is String) {
      return detail['message'] as String;
    }
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }

    final dynamic message = data['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    return 'Ocorreu um erro inesperado.';
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
