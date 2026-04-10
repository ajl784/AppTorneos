import 'package:http/http.dart' as http;

import 'package:front/api/api_response.dart';
import 'package:front/api/app_torneos_api_client.dart';
import 'package:front/features/partidos/domain/partido.dart';

class PartidosApi {
  final AppTorneosApiClient _api;

  PartidosApi({required String baseUrl, http.Client? client})
    : _api = AppTorneosApiClient(baseUrl: baseUrl, client: client);

  Future<ApiResponse<List<Partido>>> listPartidos({
    int? limit,
    int? offset,
    int? torneoId,
    String? estado,
  }) async {
    final res = await _api.getRaw(
      '/partidos',
      queryParameters: {
        'limit': limit?.toString(),
        'offset': offset?.toString(),
        'torneoId': torneoId?.toString(),
        'estado': estado,
      },
    );

    final data = res.data;
    if (data is! List) {
      throw const FormatException('Respuesta inesperada (partidos no es List)');
    }

    final partidos = data
        .whereType<Map>()
        .map((item) => Partido.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    return ApiResponse<List<Partido>>(data: partidos, meta: res.meta);
  }

  Future<Partido> getPartidoById(int idPartido) async {
    final res = await _api.getRaw('/partidos/$idPartido');
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (partido no es Map)');
    }

    return Partido.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Partido> createPartido(PartidoCreate payload) async {
    final res = await _api.postRaw('/partidos', body: payload.toJson());
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (partido no es Map)');
    }

    return Partido.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Partido> updatePartido(int idPartido, PartidoUpdate payload) async {
    final res = await _api.putRaw(
      '/partidos/$idPartido',
      body: payload.toJson(),
    );
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (partido no es Map)');
    }

    return Partido.fromJson(Map<String, dynamic>.from(data));
  }

  Future<bool> deletePartido(int idPartido) async {
    final res = await _api.deleteRaw('/partidos/$idPartido');
    final data = res.data;

    if (data is Map) {
      final deleted = data['deleted'];
      if (deleted is bool) return deleted;
    }

    return true;
  }

  Future<RegistrarPuntuacionesResult> registrarPuntuacionesArbitro({
    required int idPartido,
    required RegistrarPuntuacionesPayload payload,
  }) async {
    final res = await _api.postRaw(
      '/partidos/$idPartido/puntuaciones',
      body: payload.toJson(),
    );

    final data = res.data;
    if (data is! Map) {
      throw const FormatException(
        'Respuesta inesperada (registrar puntuaciones no es Map)',
      );
    }

    return RegistrarPuntuacionesResult.fromJson(
      Map<String, dynamic>.from(data),
    );
  }
}
