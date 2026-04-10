import 'package:front/api/api_response.dart';
import 'package:front/api/app_torneos_api_client.dart';
import 'package:front/features/tipos_torneo/domain/tipo_torneo.dart';

class TiposTorneoApi {
  final AppTorneosApiClient _client;

  final String baseUrl;

  TiposTorneoApi({required this.baseUrl})
    : _client = AppTorneosApiClient(baseUrl: baseUrl);

  Future<ApiResponse<List<TipoTorneo>>> listTiposTorneo({
    int? limit,
    int? offset,
  }) async {
    final res = await _client.getRaw(
      '/tipos-torneo',
      queryParameters: {
        if (limit != null) 'limit': '$limit',
        if (offset != null) 'offset': '$offset',
      },
    );

    final data = (res.data as List<dynamic>)
        .map((e) => TipoTorneo.fromJson(e as Map<String, dynamic>))
        .toList();

    return ApiResponse(data: data, meta: res.meta);
  }
}
