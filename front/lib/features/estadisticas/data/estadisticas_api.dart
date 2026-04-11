import 'package:http/http.dart' as http;

import 'package:front/api/api_response.dart';
import 'package:front/api/app_torneos_api_client.dart';
import 'package:front/features/estadisticas/domain/estadisticas_models.dart';

class EstadisticasApi {
  final AppTorneosApiClient _api;

  EstadisticasApi({required String baseUrl, http.Client? client})
      : _api = AppTorneosApiClient(baseUrl: baseUrl, client: client);

  Future<ApiResponse<List<EquipoUsuario>>> listEquiposUsuario(int idUsuario) async {
    final res = await _api.getRaw('/estadisticas/equipos-usuario/$idUsuario');
    final data = res.data;

    if (data is! List) {
      throw const FormatException('Respuesta inesperada (equipos no es List)');
    }

    final equipos = data
        .whereType<Map>()
        .map((item) => EquipoUsuario.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    return ApiResponse<List<EquipoUsuario>>(data: equipos, meta: res.meta);
  }

  Future<ApiResponse<EloHistorialResponse>> getEloHistorial(
    int idUsuario, {
    int? equipoId,
  }) async {
    final res = await _api.getRaw(
      '/estadisticas/elo-historial/$idUsuario',
      queryParameters: {
        'equipoId': equipoId?.toString(),
      },
    );

    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (elo-historial no es Map)');
    }

    return ApiResponse<EloHistorialResponse>(
      data: EloHistorialResponse.fromJson(Map<String, dynamic>.from(data)),
      meta: res.meta,
    );
  }

  Future<ApiResponse<RankingResponse>> getRanking(
    int idUsuario, {
    int? equipoId,
  }) async {
    final res = await _api.getRaw(
      '/estadisticas/ranking/$idUsuario',
      queryParameters: {
        'equipoId': equipoId?.toString(),
      },
    );

    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (ranking no es Map)');
    }

    return ApiResponse<RankingResponse>(
      data: RankingResponse.fromJson(Map<String, dynamic>.from(data)),
      meta: res.meta,
    );
  }
}
