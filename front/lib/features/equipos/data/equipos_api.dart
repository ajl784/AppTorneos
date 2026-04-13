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
    int? categoriaId,
  }) async {
    final res = await _api.getRaw(
      '/equipos',
      queryParameters: {
        'limit': limit?.toString(),
        'offset': offset?.toString(),
        'nombre': nombre,
        'categoriaId': categoriaId?.toString(),
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

  Future<Map<String, dynamic>> solicitarIngresoEquipo({
    required int idEquipo,
    required String descripcion,
    required String token,
  }) async {
    final res = await _api.postRaw(
      '/equipos/$idEquipo/solicitudes',
      body: {
        'descripcion': descripcion,
      },
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    throw const FormatException('Respuesta inesperada al solicitar ingreso');
  }

  Future<List<Map<String, dynamic>>> listSolicitudesIngresoEquipo({
    required int idEquipo,
    required String token,
    String? estado,
  }) async {
    final res = await _api.getRaw(
      '/equipos/$idEquipo/solicitudes',
      headers: {'Authorization': 'Bearer $token'},
      queryParameters: estado == null ? null : {'estado': estado},
    );

    if (res.data is! List) {
      throw const FormatException('Respuesta inesperada (solicitudes no es List)');
    }

    return (res.data as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> decidirSolicitudIngresoEquipo({
    required int idSolicitudEquipo,
    required bool aceptar,
    required String token,
  }) async {
    final res = await _api.patchRaw(
      '/equipos/solicitudes/$idSolicitudEquipo/decision',
      body: {'aceptar': aceptar},
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }

    throw const FormatException('Respuesta inesperada al decidir solicitud');
  }
}
