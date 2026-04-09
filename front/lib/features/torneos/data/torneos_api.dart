import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:front/features/torneos/domain/torneo.dart';

class TorneosApi {
  final String baseUrl;
  final http.Client _client;

  List<Torneo> lastTorneos = const <Torneo>[];
  Map<String, dynamic>? lastMeta;

  TorneosApi({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  String get _normalizedBaseUrl => baseUrl.replaceAll(RegExp(r'/+$'), '');

  Uri _buildUri(String path) {
    final base = _normalizedBaseUrl;
    final apiBase = base.endsWith('/api/v1') ? base : '$base/api/v1';
    final safePath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$apiBase/$safePath');
  }

  Future<List<Torneo>> fetchTorneos() async {
    final uri = _buildUri('/torneos');
    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    dynamic data = decoded;
    Map<String, dynamic>? meta;

    if (decoded is Map<String, dynamic>) {
      final okValue = decoded['ok'];
      if (okValue == false) {
        throw Exception(decoded['error']?.toString() ?? 'Respuesta ok=false');
      }

      if (decoded.containsKey('data')) {
        data = decoded['data'];
      }

      final decodedMeta = decoded['meta'];
      if (decodedMeta is Map<String, dynamic>) {
        meta = decodedMeta;
      }
    }

    if (data is! List) {
      throw const FormatException('Respuesta JSON inesperada (data no es List)');
    }

    final torneos = data
        .whereType<Map>()
        .map((item) => Torneo.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    lastTorneos = torneos;
    lastMeta = meta;

    return torneos;
  }
}
