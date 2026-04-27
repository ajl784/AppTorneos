
import 'package:flutter/material.dart';
import 'package:front/state/jwt_storage.dart';
import 'package:front/features/invitaciones/data/invitaciones_api.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/features/equipos/data/equipos_api.dart';
import 'package:front/peticion/api_config.dart';

class GestionInvitacionesScreen extends StatefulWidget {
  const GestionInvitacionesScreen({Key? key}) : super(key: key);

  @override
  State<GestionInvitacionesScreen> createState() => _GestionInvitacionesScreenState();
}

class _GestionInvitacionesScreenState extends State<GestionInvitacionesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _invitacionesEquipos = [];
  List<Map<String, dynamic>> _invitacionesTorneos = [];
  Map<String, String> _nombresEquipos = {};
  Map<String, String> _nombresTorneos = {};

  @override
  void initState() {
    super.initState();
    _loadInvitaciones();
  }

  Future<void> _loadInvitaciones() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userMap = await JwtStorage.getUser();
      if (userMap == null || userMap['id_usuario'] == null) throw Exception('No hay usuario logueado');
      final int idUsuario = int.parse(userMap['id_usuario'].toString());
      final api = InvitacionesApi(baseUrl: ApiConfig.baseUrl);
      final invitaciones = await api.getInvitacionesPendientes(idUsuario);
      final equiposApi = EquiposApi(baseUrl: ApiConfig.baseUrl);
      final torneosApi = TorneosApi(baseUrl: ApiConfig.baseUrl);

      List<Map<String, dynamic>> equipos = [];
      List<Map<String, dynamic>> torneos = [];
      Map<String, String> nombresEquipos = {};
      Map<String, String> nombresTorneos = {};

      for (final inv in invitaciones) {
        if (inv['tipo'] == 'jugador_equipo' && inv['id_equipo'] != null) {
          equipos.add(inv);
          final idEquipo = int.tryParse(inv['id_equipo'].toString());
          if (idEquipo != null && !nombresEquipos.containsKey(inv['id_equipo'].toString())) {
            try {
              final equipo = await equiposApi.getEquipoById(idEquipo);
              nombresEquipos[inv['id_equipo'].toString()] = equipo.nombre;
            } catch (_) {
              nombresEquipos[inv['id_equipo'].toString()] = 'Equipo #${inv['id_equipo']}';
            }
          }
        } else if (inv['tipo'] == 'arbitro_torneo' && inv['id_torneo'] != null) {
          torneos.add(inv);
          final idTorneo = int.tryParse(inv['id_torneo'].toString());
          if (idTorneo != null && !nombresTorneos.containsKey(inv['id_torneo'].toString())) {
            try {
              final torneo = await torneosApi.fetchTorneoById(idTorneo);
              nombresTorneos[inv['id_torneo'].toString()] = torneo.nombre;
            } catch (_) {
              nombresTorneos[inv['id_torneo'].toString()] = 'Torneo #${inv['id_torneo']}';
            }
          }
        }
      }

      setState(() {
        _invitacionesEquipos = equipos;
        _invitacionesTorneos = torneos;
        _nombresEquipos = nombresEquipos;
        _nombresTorneos = nombresTorneos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _responderInvitacion(int idInvitacion, bool aceptar) async {
    try {
      final api = InvitacionesApi(baseUrl: ApiConfig.baseUrl);
      if (aceptar) {
        await api.aceptarInvitacion(idInvitacion);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitación aceptada.')));
      } else {
        await api.rechazarInvitacion(idInvitacion);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitación rechazada.')));
      }
      await _loadInvitaciones();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de invitaciones'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : ListView(
                    children: [
                      const Text(
                        'Mis invitaciones a equipos',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      if (_invitacionesEquipos.isEmpty)
                        const Text('No tienes invitaciones a equipos pendientes.')
                      else
                        ..._invitacionesEquipos.map((inv) {
                          final nombreEquipo = _nombresEquipos[inv['id_equipo'].toString()] ?? 'Equipo';
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.group),
                              title: Text(nombreEquipo),
                              subtitle: const Text('Te han invitado a unirte a este equipo.'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => _responderInvitacion(int.parse(inv['id_invitacion'].toString()), false),
                                    child: const Text('Rechazar'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _responderInvitacion(int.parse(inv['id_invitacion'].toString()), true),
                                    child: const Text('Aceptar'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 32),
                      const Text(
                        'Mis invitaciones a arbitrar torneos',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      if (_invitacionesTorneos.isEmpty)
                        const Text('No tienes invitaciones a arbitrar torneos pendientes.')
                      else
                        ..._invitacionesTorneos.map((inv) {
                          final nombreTorneo = _nombresTorneos[inv['id_torneo'].toString()] ?? 'Torneo';
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.sports),
                              title: Text(nombreTorneo),
                              subtitle: const Text('Te han invitado a arbitrar este torneo.'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => _responderInvitacion(int.parse(inv['id_invitacion'].toString()), false),
                                    child: const Text('Rechazar'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _responderInvitacion(int.parse(inv['id_invitacion'].toString()), true),
                                    child: const Text('Aceptar'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}
