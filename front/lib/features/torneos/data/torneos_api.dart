import 'package:http/http.dart' as http;

import 'package:front/api/app_torneos_api_client.dart';
import 'package:front/api/api_response.dart';
import 'package:front/features/torneos/domain/torneo.dart';
import 'package:front/features/torneos/domain/torneo_clasificacion.dart';
import 'package:front/features/torneos/domain/torneo_enfrentamientos_result.dart';
import 'package:front/features/torneos/domain/torneo_formulario.dart';
import 'package:front/features/torneos/domain/torneo_partidos.dart';

class TorneosApi {
  final AppTorneosApiClient _api;

  List<Torneo> lastTorneos = const <Torneo>[];
  Map<String, dynamic>? lastMeta;

  TorneosApi({required this.baseUrl, http.Client? client})
    : _api = AppTorneosApiClient(baseUrl: baseUrl, client: client);

  final String baseUrl;

  Future<ApiResponse<List<Torneo>>> listTorneos({
    int? limit,
    int? offset,
    String? estado,
    int? organizadorId,
    int? categoriaId,
    int? tipoTorneoId,
  }) async {
    final res = await _api.getRaw(
      '/torneos',
      queryParameters: {
        'limit': limit?.toString(),
        'offset': offset?.toString(),
        'estado': estado,
        'organizadorId': organizadorId?.toString(),
        'categoriaId': categoriaId?.toString(),
        'tipoTorneoId': tipoTorneoId?.toString(),
      },
    );

    final data = res.data;
    if (data is! List) {
      throw const FormatException('Respuesta JSON inesperada (torneos no es List)');
    }

    final torneos = data
        .whereType<Map>()
        .map((item) => Torneo.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    return ApiResponse<List<Torneo>>(data: torneos, meta: res.meta);
  }

  Future<List<Torneo>> fetchTorneos() async {
    final res = await _api.getRaw('/torneos');
    final data = res.data;

    if (data is! List) {
      throw const FormatException(
        'Respuesta JSON inesperada (torneos no es List)',
      );
    }

    final torneos = data
        .whereType<Map>()
        .map((item) => Torneo.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    lastTorneos = torneos;
    lastMeta = res.meta == null
        ? null
        : {
            'limit': res.meta!.limit,
            'offset': res.meta!.offset,
            'count': res.meta!.count,
          };

    return torneos;
  }

  Future<Torneo> fetchTorneoById(int idTorneo) async {
    final res = await _api.getRaw('/torneos/$idTorneo');
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (torneo no es Map)');
    }
    return Torneo.fromJson(Map<String, dynamic>.from(data));
  }

  Future<TorneoClasificacion> fetchClasificacionTorneo(int idTorneo) async {
    final res = await _api.getRaw('/torneos/$idTorneo/clasificacion');
    final data = res.data;
    if (data is! Map) {
      throw const FormatException(
        'Respuesta inesperada (clasificacion no es Map)',
      );
    }
    return TorneoClasificacion.fromJson(Map<String, dynamic>.from(data));
  }

  Future<TorneoPartidos> fetchPartidosTorneo(int idTorneo) async {
    final res = await _api.getRaw('/torneos/$idTorneo/partidos');
    final data = res.data;
    if (data is! Map) {
      throw const FormatException(
        'Respuesta inesperada (partidos torneo no es Map)',
      );
    }
    return TorneoPartidos.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Torneo> createTorneo(TorneoCreate payload) async {
    final res = await _api.postRaw('/torneos', body: payload.toJson());
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (torneo no es Map)');
    }
    return Torneo.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Torneo> updateTorneo(
    int idTorneo,
    TorneoUpdate payload, {
    String? token,
  }) async {
    final res = await _api.putRaw(
      '/torneos/$idTorneo',
      body: payload.toJson(),
      headers: token == null ? null : {'Authorization': 'Bearer $token'},
    );
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (torneo no es Map)');
    }
    return Torneo.fromJson(Map<String, dynamic>.from(data));
  }

  Future<bool> deleteTorneo(int idTorneo) async {
    final res = await _api.deleteRaw('/torneos/$idTorneo');
    final data = res.data;
    if (data is Map) {
      final deleted = data['deleted'];
      if (deleted is bool) return deleted;
    }
    return true;
  }

  Future<TorneoFormulario> getFormularioTorneo(int idTorneo) async {
    final res = await _api.getRaw('/torneos/$idTorneo/formulario');
    final data = res.data;
    if (data is! Map) {
      throw const FormatException(
        'Respuesta inesperada (formulario no es Map)',
      );
    }
    return TorneoFormulario.fromJson(Map<String, dynamic>.from(data));
  }

  Future<TorneoFormulario> updateFormularioTorneo({
    required int idTorneo,
    required UpdateFormularioPayload payload,
  }) async {
    final res = await _api.putRaw(
      '/torneos/$idTorneo/formulario',
      body: payload.toJson(),
    );
    final data = res.data;
    if (data is! Map) {
      throw const FormatException(
        'Respuesta inesperada (formulario no es Map)',
      );
    }
    return TorneoFormulario.fromJson(Map<String, dynamic>.from(data));
  }

  Future<TorneoEnfrentamientosResult> generarEnfrentamientos(
    int idTorneo,
  ) async {
    final res = await _api.postRaw(
      '/torneos/$idTorneo/generar-enfrentamientos',
    );
    final data = res.data;
    if (data is! Map) {
      throw const FormatException(
        'Respuesta inesperada (enfrentamientos no es Map)',
      );
    }
    return TorneoEnfrentamientosResult.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  /// Envía una solicitud de unión a un torneo
  Future<Map<String, dynamic>> enviarSolicitudUnirse({
    required int idTorneo,
    required int idEquipo,
    Map<String, dynamic>? respuesta,
  }) async {
    final res = await _api.postRaw(
      '/torneos/$idTorneo/solicitudes',
      body: {
        'id_equipo': idEquipo,
        'respuesta': respuesta,
      },
    );
    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    throw const FormatException('Respuesta inesperada al enviar solicitud');
  }


    /// Obtiene las solicitudes de inscripción de un torneo con estado opcional
  Future<List<Map<String, dynamic>>> getSolicitudesInscripcion(int idTorneo, {String? estado}) async {
    final res = await _api.getRaw(
      '/torneos/$idTorneo/solicitudes',
      queryParameters: estado != null ? {'estado': estado} : null,
    );
    if (res.data is List) {
      return (res.data as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

    /// Responde a una solicitud de inscripción (aceptar o denegar)
  Future<Map<String, dynamic>> responderSolicitudInscripcion({
    required int idParticipacionEquipo,
    required bool aceptar,
  }) async {
    final res = await _api.patchRaw(
      '/participaciones/$idParticipacionEquipo/decision',
      body: {'aceptar': aceptar},
    );
    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    throw const FormatException('Respuesta inesperada al responder solicitud');
  }

  Future<TorneoEnfrentamientosResult> generarBracketEliminacion(
    int idTorneo,
  ) async {
    final res = await _api.postRaw(
      '/torneos/$idTorneo/bracket/eliminacion/generar',
    );
    final data = res.data;
    if (data is! Map) {
      throw const FormatException(
        'Respuesta inesperada (bracket generar no es Map)',
      );
    }
    return TorneoEnfrentamientosResult.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<TorneoEnfrentamientosResult> avanzarRondaEliminacion(
    int idTorneo,
  ) async {
    final res = await _api.postRaw(
      '/torneos/$idTorneo/bracket/eliminacion/avanzar',
    );
    final data = res.data;
    if (data is! Map) {
      throw const FormatException(
        'Respuesta inesperada (bracket avanzar no es Map)',
      );
    }
    return TorneoEnfrentamientosResult.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  /// Obtiene las participaciones (equipos inscritos) de un torneo
  Future<List<Map<String, dynamic>>> getParticipacionesTorneo(int idTorneo) async {
    final res = await _api.getRaw('/torneos/$idTorneo/participaciones');
    if (res.data is List) {
      return (res.data as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Elimina una participación (equipo del torneo)
  Future<void> deleteParticipacion(
    int idParticipacionEquipo, {
    String? token,
  }) async {
    await _api.deleteRaw(
      '/participaciones/$idParticipacionEquipo',
      headers: token == null ? null : {'Authorization': 'Bearer $token'},
    );
  }
}
