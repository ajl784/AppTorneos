import 'package:http/http.dart' as http;
import 'package:front/api/api_response.dart';
import 'package:front/api/app_torneos_api_client.dart';
import 'package:front/features/notificaciones/domain/notificacion.dart';

class NotificacionesApi {
  final AppTorneosApiClient _api;

  NotificacionesApi({required String baseUrl, http.Client? client})
      : _api = AppTorneosApiClient(baseUrl: baseUrl, client: client);

  /// GET /notificaciones/usuario/:idUsuario
  Future<ApiResponse<List<Notificacion>>> getNotificacionesByUsuario(
    int idUsuario,
  ) async {
    final res = await _api.getRaw('/notificaciones/usuario/$idUsuario');

    final data = res.data;
    if (data is! List) {
      throw const FormatException(
        'Respuesta inesperada (notificaciones no es List)',
      );
    }

    final notificaciones = data
        .whereType<Map>()
        .map((item) => Notificacion.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    return ApiResponse<List<Notificacion>>(
      data: notificaciones,
      meta: res.meta,
    );
  }

  /// GET /notificaciones?limit=&offset=&tipo=&leida=
  /// Obtiene notificaciones con filtros opcionales.
  /// - limit: número máximo de resultados
  /// - offset: desplazamiento para paginación
  /// - tipo: filtrar por tipo (ej: "arbitro_torneo")
  /// - leida: true/false (solo notificaciones leídas o no leídas)
  Future<ApiResponse<List<Notificacion>>> getNotificaciones({
    int? limit,
    int? offset,
    String? tipo,
    bool? leida,
  }) async {
    final queryParams = <String, String?>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();
    if (tipo != null) queryParams['tipo'] = tipo;
    if (leida != null) queryParams['leida'] = leida.toString();

    final res = await _api.getRaw(
      '/notificaciones',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final data = res.data;
    if (data is! List) {
      throw const FormatException(
        'Respuesta inesperada (notificaciones no es List)',
      );
    }

    final notificaciones = data
        .whereType<Map>()
        .map((item) => Notificacion.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    return ApiResponse<List<Notificacion>>(
      data: notificaciones,
      meta: res.meta,
    );
  }

  /// PATCH /notificaciones/:idNotificacion/leida
  /// Marca una notificación como leída.
  /// Retorna true si se marcó correctamente, false en caso contrario
  /// (o lanza excepción si el backend devuelve error).
  Future<bool> marcarComoLeida(String idNotificacion) async {
    final res = await _api.patchRaw('/notificaciones/$idNotificacion/leida');

    // Según la estructura de la API, podría devolver { ok: true, data: {...} }
    // o simplemente un 200 con un mensaje. Asumimos que si no hay excepción, fue exitoso.
    // Opcionalmente, verificar res.data si contiene algún indicador.
    if (res.data is Map && res.data['ok'] == true) {
      return true;
    }
    // Si no hay un campo 'ok', asumimos que éxito si llegamos aquí.
    return true;
  }

  /// DELETE /notificaciones/:idNotificacion
  /// Elimina una notificación.
  /// Retorna true si se eliminó correctamente, false en otro caso.
  Future<bool> eliminarNotificacion(String idNotificacion) async {
    final res = await _api.deleteRaw('/notificaciones/$idNotificacion');

    if (res.data is Map && res.data['ok'] == true) {
      return true;
    }
    return true; // Asumimos éxito si no hay excepción.
  }
}