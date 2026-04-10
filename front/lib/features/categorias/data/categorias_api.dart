import 'package:front/api/api_response.dart';
import 'package:front/api/app_torneos_api_client.dart';
import 'package:front/features/categorias/domain/categoria.dart';
import 'package:front/features/tipos_torneo/domain/tipo_torneo.dart';

class CategoriasApi {
  final AppTorneosApiClient _client;

  final String baseUrl;

  CategoriasApi({required this.baseUrl})
    : _client = AppTorneosApiClient(baseUrl: baseUrl);

  Future<ApiResponse<List<Categoria>>> listCategorias({
    int? limit,
    int? offset,
  }) async {
    final res = await _client.getRaw(
      '/categorias',
      queryParameters: {
        if (limit != null) 'limit': '$limit',
        if (offset != null) 'offset': '$offset',
      },
    );

    final data = (res.data as List<dynamic>)
        .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
        .toList();

    return ApiResponse(data: data, meta: res.meta);
  }

  Future<Categoria> createCategoria(CategoriaCreate payload) async {
    final res = await _client.postRaw('/categorias', body: payload.toJson());
    return Categoria.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<TipoTorneo>> listTiposTorneoByCategoria(int idCategoria) async {
    final res = await _client.getRaw('/categorias/$idCategoria/tipos-torneo');
    return (res.data as List<dynamic>)
        .map((e) => TipoTorneo.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
