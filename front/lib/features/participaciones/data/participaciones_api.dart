import 'package:http/http.dart' as http;

import 'package:front/api/api_response.dart';
import 'package:front/api/app_torneos_api_client.dart';
import 'package:front/features/participaciones/domain/participacion.dart';

class ParticipacionesApi {
  final AppTorneosApiClient _api;

  ParticipacionesApi({required String baseUrl, http.Client? client})
    : _api = AppTorneosApiClient(baseUrl: baseUrl, client: client);

  Future<ApiResponse<List<Participacion>>> listParticipaciones({
    int? limit,
    int? offset,
    int? torneoId,
    int? equipoId,
    String? estado,
  }) async {
    final res = await _api.getRaw(
      '/participaciones',
      queryParameters: {
        'limit': limit?.toString(),
        'offset': offset?.toString(),
        'torneoId': torneoId?.toString(),
        'equipoId': equipoId?.toString(),
        'estado': estado,
      },
    );

    final data = res.data;
    if (data is! List) {
      throw const FormatException(
        'Respuesta inesperada (participaciones no es List)',
      );
    }

    final participaciones = data
        .whereType<Map>()
        .map((item) => Participacion.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    return ApiResponse<List<Participacion>>(
      data: participaciones,
      meta: res.meta,
    );
  }

  Future<Participacion> getParticipacionById(int idParticipacionEquipo) async {
    final res = await _api.getRaw('/participaciones/$idParticipacionEquipo');
    final data = res.data;
    if (data is! Map) {
      throw const FormatException(
        'Respuesta inesperada (participacion no es Map)',
      );
    }

    return Participacion.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Participacion> createParticipacion(ParticipacionCreate payload) async {
    final res = await _api.postRaw('/participaciones', body: payload.toJson());
    final data = res.data;
    if (data is! Map) {
      throw const FormatException(
        'Respuesta inesperada (participacion no es Map)',
      );
    }

    return Participacion.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Participacion> updateParticipacion(
    int idParticipacionEquipo,
    ParticipacionUpdate payload,
  ) async {
    final res = await _api.putRaw(
      '/participaciones/$idParticipacionEquipo',
      body: payload.toJson(),
    );

    final data = res.data;
    if (data is! Map) {
      throw const FormatException(
        'Respuesta inesperada (participacion no es Map)',
      );
    }

    return Participacion.fromJson(Map<String, dynamic>.from(data));
  }

  Future<bool> deleteParticipacion(int idParticipacionEquipo) async {
    final res = await _api.deleteRaw('/participaciones/$idParticipacionEquipo');
    final data = res.data;

    if (data is Map) {
      final deleted = data['deleted'];
      if (deleted is bool) return deleted;
    }

    return true;
  }

  Future<ApiResponse<List<Participacion>>> listSolicitudesByTorneo({
    required int idTorneo,
    String? estado,
  }) async {
    final res = await _api.getRaw(
      '/torneos/$idTorneo/solicitudes',
      queryParameters: {'estado': estado},
    );

    final data = res.data;
    if (data is! List) {
      throw const FormatException(
        'Respuesta inesperada (solicitudes no es List)',
      );
    }

    final solicitudes = data
        .whereType<Map>()
        .map((item) => Participacion.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    return ApiResponse<List<Participacion>>(data: solicitudes, meta: res.meta);
  }

  Future<Participacion> createSolicitudByTorneo({
    required int idTorneo,
    required SolicitudCreate payload,
  }) async {
    final res = await _api.postRaw(
      '/torneos/$idTorneo/solicitudes',
      body: payload.toJson(),
    );

    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (solicitud no es Map)');
    }

    return Participacion.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Participacion> decidirSolicitud({
    required int idParticipacionEquipo,
    required DecisionSolicitudPayload payload,
  }) async {
    final res = await _api.patchRaw(
      '/participaciones/$idParticipacionEquipo/decision',
      body: payload.toJson(),
    );

    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (decision no es Map)');
    }

    return Participacion.fromJson(Map<String, dynamic>.from(data));
  }
}
