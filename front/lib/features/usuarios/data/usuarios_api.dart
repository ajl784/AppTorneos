import 'package:http/http.dart' as http;

import 'package:front/api/api_response.dart';
import 'package:front/api/app_torneos_api_client.dart';
import 'package:front/features/usuarios/domain/usuario.dart';

class UsuariosApi {
  final AppTorneosApiClient _api;

  UsuariosApi({required String baseUrl, http.Client? client})
    : _api = AppTorneosApiClient(baseUrl: baseUrl, client: client);

  Future<ApiResponse<List<Usuario>>> listUsuarios({
    int? limit,
    int? offset,
    String? q,
  }) async {
    final res = await _api.getRaw(
      '/usuarios',
      queryParameters: {
        'limit': limit?.toString(),
        'offset': offset?.toString(),
        'q': q,
      },
    );

    final data = res.data;
    if (data is! List) {
      throw const FormatException('Respuesta inesperada (usuarios no es List)');
    }

    final usuarios = data
        .whereType<Map>()
        .map((item) => Usuario.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    return ApiResponse<List<Usuario>>(data: usuarios, meta: res.meta);
  }

  Future<Usuario> getUsuarioById(int idUsuario) async {
    final res = await _api.getRaw('/usuarios/$idUsuario');
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (usuario no es Map)');
    }

    return Usuario.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Usuario> createUsuario(UsuarioCreate payload) async {
    final res = await _api.postRaw('/usuarios', body: payload.toJson());
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (usuario no es Map)');
    }

    return Usuario.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Usuario> updateUsuario(int idUsuario, UsuarioUpdate payload) async {
    final res = await _api.putRaw(
      '/usuarios/$idUsuario',
      body: payload.toJson(),
    );
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (usuario no es Map)');
    }

    return Usuario.fromJson(Map<String, dynamic>.from(data));
  }

  Future<bool> deleteUsuario(int idUsuario) async {
    final res = await _api.deleteRaw('/usuarios/$idUsuario');
    final data = res.data;

    if (data is Map) {
      final deleted = data['deleted'];
      if (deleted is bool) return deleted;
    }

    return true;
  }
}
