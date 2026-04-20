import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:front/api/api_exception.dart';
import 'package:front/api/api_meta.dart';
import 'package:front/api/api_response.dart';

class AppTorneosApiClient {
  final String baseUrl;
  final http.Client _client;

  AppTorneosApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  String get _normalizedBaseUrl => baseUrl.replaceAll(RegExp(r'/+$'), '');

  Uri buildUri(String path, {Map<String, String?>? queryParameters}) {
    final base = _normalizedBaseUrl;
    final apiBase = base.endsWith('/api/v1') ? base : '$base/api/v1';
    final safePath = path.startsWith('/') ? path.substring(1) : path;

    final uri = Uri.parse('$apiBase/$safePath');

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final qp = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value == null) return;
      if (value.trim().isEmpty) return;
      qp[key] = value;
    });

    return uri.replace(queryParameters: qp);
  }

  Future<ApiResponse<dynamic>> getRaw(
    String path, {
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _send(
      'GET',
      path,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<ApiResponse<dynamic>> postRaw(
    String path, {
    Object? body,
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _send(
      'POST',
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<ApiResponse<dynamic>> putRaw(
    String path, {
    Object? body,
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _send(
      'PUT',
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<ApiResponse<dynamic>> patchRaw(
    String path, {
    Object? body,
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _send(
      'PATCH',
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<ApiResponse<dynamic>> deleteRaw(
    String path, {
    Object? body,
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _send(
      'DELETE',
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<ApiResponse<dynamic>> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = buildUri(path, queryParameters: queryParameters);

    final mergedHeaders = <String, String>{
      'Accept': 'application/json',
      ...?headers,
    };

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: mergedHeaders);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: {...mergedHeaders, 'Content-Type': 'application/json'},
            body: body == null ? null : jsonEncode(body),
          );
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: {...mergedHeaders, 'Content-Type': 'application/json'},
            body: body == null ? null : jsonEncode(body),
          );
          break;
        case 'PATCH':
          response = await _client.patch(
            uri,
            headers: {...mergedHeaders, 'Content-Type': 'application/json'},
            body: body == null ? null : jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await _client.delete(
            uri,
            headers: {...mergedHeaders, 'Content-Type': 'application/json'},
            body: body == null ? null : jsonEncode(body),
          );
          break;
        default:
          throw ApiException(
            statusCode: 0,
            message: 'Método HTTP inválido: $method',
          );
      }
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Error de red: $e');
    }

    final decoded = tryDecodeJson(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toApiException(response.statusCode, decoded, response.body);
    }

    if (decoded is Map<String, dynamic>) {
      final okValue = decoded['ok'];
      if (okValue == false) {
        throw _toApiException(response.statusCode, decoded, response.body);
      }

      final data = decoded.containsKey('data') ? decoded['data'] : decoded;
      final metaValue = decoded['meta'];
      final meta = (metaValue is Map<String, dynamic>)
          ? ApiMeta.fromJson(metaValue)
          : null;
      return ApiResponse<dynamic>(data: data, meta: meta);
    }

    return ApiResponse<dynamic>(data: decoded, meta: null);
  }

  static Object? tryDecodeJson(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  static ApiException _toApiException(
    int statusCode,
    Object? decoded,
    String rawBody,
  ) {
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        return ApiException(
          statusCode: statusCode,
          message: (error['message']?.toString()) ?? 'Error HTTP $statusCode',
          details: error['details'],
          rawBody: decoded,
        );
      }

      if (decoded['message'] != null) {
        return ApiException(
          statusCode: statusCode,
          message: decoded['message'].toString(),
          rawBody: decoded,
        );
      }
    }

    return ApiException(
      statusCode: statusCode,
      message: 'HTTP $statusCode',
      rawBody: decoded ?? rawBody,
    );
  }
}
