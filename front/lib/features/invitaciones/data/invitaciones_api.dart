import 'package:front/api/app_torneos_api_client.dart';

class InvitacionesApi {
  final AppTorneosApiClient _api;
  InvitacionesApi({required String baseUrl}) : _api = AppTorneosApiClient(baseUrl: baseUrl);

  Future<List<Map<String, dynamic>>> getInvitacionesPendientes(int idUsuario) async {
    final res = await _api.getRaw('/invitaciones/pendientes/$idUsuario');
    final data = res.data;
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<bool> aceptarInvitacion(int idInvitacion) async {
    final res = await _api.postRaw('/invitaciones/$idInvitacion/aceptar');
    return res.data != null;
  }

  Future<bool> rechazarInvitacion(int idInvitacion) async {
    final res = await _api.postRaw('/invitaciones/$idInvitacion/rechazar');
    return res.data != null;
  }
}
