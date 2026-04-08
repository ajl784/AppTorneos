import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Torneo {
  final int id;
  final String nombre;

  const Torneo({
    required this.id,
    required this.nombre,
  });

  factory Torneo.fromJson(Map<String, dynamic> json) {
    return Torneo(
      id: (json['id'] as num).toInt(),
      nombre: (json['nombre'] as String?) ?? '',
    );
  }
}

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

class TorneosScreenExample extends StatefulWidget {
  const TorneosScreenExample({super.key});

  @override
  State<TorneosScreenExample> createState() => _TorneosScreenExampleState();
}

class _TorneosScreenExampleState extends State<TorneosScreenExample> {
  late final TorneosApi _api = TorneosApi(
    baseUrl: 'http://10.0.2.2:3000',
  );

  late final Future<List<Torneo>> _future = _api.fetchTorneos();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torneos (ejemplo)'),
      ),
      body: FutureBuilder<List<Torneo>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final torneos = snapshot.data ?? const <Torneo>[];

          if (torneos.isEmpty) {
            return const Center(child: Text('Sin datos'));
          }

          return ListView.separated(
            itemCount: torneos.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final torneo = torneos[index];
              return ListTile(
                title: Text(torneo.nombre),
                subtitle: Text('ID: ${torneo.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
