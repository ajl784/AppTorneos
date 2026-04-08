import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:front/features/torneos/domain/torneo.dart';

class TorneosApi {
  final String baseUrl;
  final http.Client _client;

  TorneosApi({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<List<Torneo>> fetchTorneos() async {
    final uri = Uri.parse('$baseUrl/torneos');
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

    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Torneo.fromJson)
          .toList(growable: false);
    }

    if (decoded is Map<String, dynamic> && decoded['items'] is List) {
      final items = decoded['items'] as List;
      return items
          .whereType<Map<String, dynamic>>()
          .map(Torneo.fromJson)
          .toList(growable: false);
    }

    throw const FormatException('Respuesta JSON inesperada');
  }
}
