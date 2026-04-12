import 'package:http/http.dart' as http;

import 'package:front/api/api_response.dart';
import 'package:front/api/app_torneos_api_client.dart';
import 'package:front/features/equipos/domain/equipo.dart';

class EquiposApi {
  final AppTorneosApiClient _api;

  EquiposApi({required String baseUrl, http.Client? client})
    : _api = AppTorneosApiClient(baseUrl: baseUrl, client: client);

  Future<ApiResponse<List<Equipo>>> listEquipos({
    int? limit,
    int? offset,
    String? nombre,
  }) async {
    final res = await _api.getRaw(
      '/equipos',
      queryParameters: {
        'limit': limit?.toString(),
        'offset': offset?.toString(),
        'nombre': nombre,
      },
    );

    final data = res.data;
    if (data is! List) {
      throw const FormatException('Respuesta inesperada (equipos no es List)');
    }

    final equipos = data
        .whereType<Map>()
        .map((item) => Equipo.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    return ApiResponse<List<Equipo>>(data: equipos, meta: res.meta);
  }

  Future<Equipo> getEquipoById(int idEquipo) async {
    final res = await _api.getRaw('/equipos/$idEquipo');
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (equipo no es Map)');
    }

    return Equipo.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Equipo> createEquipo(EquipoCreate payload) async {
    final res = await _api.postRaw('/equipos', body: payload.toJson());
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (equipo no es Map)');
    }

    return Equipo.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Equipo> updateEquipo(int idEquipo, EquipoUpdate payload) async {
    final res = await _api.putRaw('/equipos/$idEquipo', body: payload.toJson());
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (equipo no es Map)');
    }

    return Equipo.fromJson(Map<String, dynamic>.from(data));
  }

  Future<bool> deleteEquipo(int idEquipo) async {
    final res = await _api.deleteRaw('/equipos/$idEquipo');
    final data = res.data;

    if (data is Map) {
      final deleted = data['deleted'];
      if (deleted is bool) return deleted;
    }

    return true;
  }

  /// Obtiene los equipos de un usuario por su ID usando la ruta /equipos/usuario/<idUsuario>
    Future<ApiResponse<List<Equipo>>> getEquiposByUsuario(int idUsuario) async {
      final res = await _api.getRaw('/equipos/usuario/$idUsuario');
      final data = res.data;
      if (data is! List) {
        throw const FormatException('Respuesta inesperada (equipos no es List)');
      }
      final equipos = data
          .whereType<Map>()
          .map((item) => Equipo.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      return ApiResponse<List<Equipo>>(data: equipos, meta: res.meta);
    }
}
