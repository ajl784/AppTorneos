import 'package:http/http.dart' as http;

import 'package:front/api/api_response.dart';
import 'package:front/api/app_torneos_api_client.dart';
import 'package:front/features/calendario/domain/calendario_models.dart';

class CalendarioApi {
  final AppTorneosApiClient _api;

  CalendarioApi({required String baseUrl, http.Client? client})
      : _api = AppTorneosApiClient(baseUrl: baseUrl, client: client);

  Future<ApiResponse<CalendarioUsuarioResponse>> getCalendarioUsuario(
    int idUsuario, {
    String? desde,
    String? hasta,
    int? limit,
    int? offset,
  }) async {
    final res = await _api.getRaw(
      '/usuarios/$idUsuario/calendario',
      queryParameters: {
        'desde': desde,
        'hasta': hasta,
        'limit': limit?.toString(),
        'offset': offset?.toString(),
      },
    );

    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (calendario no es Map)');
    }

    return ApiResponse<CalendarioUsuarioResponse>(
      data: CalendarioUsuarioResponse.fromJson(Map<String, dynamic>.from(data)),
      meta: res.meta,
    );
  }
}
