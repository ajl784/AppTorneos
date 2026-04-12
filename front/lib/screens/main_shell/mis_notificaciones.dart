import 'package:front/screens/main_shell/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:front/state/auth_state.dart';
import 'package:front/state/jwt_storage.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/peticion/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MisNotificacionesScreen extends StatefulWidget {
  const MisNotificacionesScreen({super.key});

  @override
  State<MisNotificacionesScreen> createState() => _MisNotificacionesScreenState();
}

class _MisNotificacionesScreenState extends State<MisNotificacionesScreen> {
    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      // Actualiza el badge al entrar
      _updateBadge();
    }

    @override
    void dispose() {
      // Actualiza el badge al salir
      _updateBadge();
      super.dispose();
    }

    void _updateBadge() async {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        final jwtUser = await JwtStorage.getUser();
        if (jwtUser == null) {
          NotificationBadgeState.hasPending.value = false;
          return;
        }
        final int idUsuario = int.parse(jwtUser['id_usuario'].toString());
        final torneosApi = TorneosApi(baseUrl: ApiConfig.baseUrl);
        final response = await torneosApi.listTorneos(organizadorId: idUsuario);
        final torneos = response.data;
        bool found = false;
        for (final torneo in torneos) {
          final idTorneo = torneo.id;
          final url = ApiConfig.baseUrl.replaceAll('/api/v1', '') + '/api/v1/torneos/$idTorneo/solicitudes?estado=pendiente';
          final resp = await http.get(Uri.parse(url));
          if (resp.statusCode == 200) {
            final data = json.decode(resp.body);
            if (data['ok'] == true && data['meta'] != null && data['meta']['count'] > 0) {
              found = true;
              break;
            }
          }
        }
        NotificationBadgeState.hasPending.value = found;
      }
    }
  bool _loading = true;
  List<_TorneoSolicitud> _torneosConSolicitudes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotificaciones();
  }

  Future<void> _fetchNotificaciones() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final jwtUser = await JwtStorage.getUser();
      if (jwtUser == null) throw Exception('No hay usuario logueado');
      final int idUsuario = int.parse(jwtUser['id_usuario'].toString());
      final torneosApi = TorneosApi(baseUrl: ApiConfig.baseUrl);
      final response = await torneosApi.listTorneos(organizadorId: idUsuario);
      final torneos = response.data;
      List<_TorneoSolicitud> torneosConSolicitudes = [];
      for (final torneo in torneos) {
        final idTorneo = torneo.id;
        final nombreTorneo = torneo.nombre;
        final url = ApiConfig.baseUrl.replaceAll('/api/v1', '') + '/api/v1/torneos/$idTorneo/solicitudes?estado=pendiente';
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          if (data['ok'] == true && data['meta'] != null && data['meta']['count'] > 0) {
            torneosConSolicitudes.add(_TorneoSolicitud(
              id: idTorneo,
              nombre: nombreTorneo,
              count: data['meta']['count'],
            ));
          }
        }
      }
      setState(() {
        _torneosConSolicitudes = torneosConSolicitudes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar notificaciones';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _torneosConSolicitudes.isEmpty
                  ? const Center(child: Text('No tienes notificaciones nuevas.'))
                  : ListView.builder(
                      itemCount: _torneosConSolicitudes.length,
                      itemBuilder: (context, index) {
                        final torneo = _torneosConSolicitudes[index];
                        return ListTile(
                          leading: const Icon(Icons.notifications_active),
                          title: Text('Tu torneo "${torneo.nombre}" tiene solicitudes de unión pendientes'),
                          subtitle: Text('${torneo.count} solicitud(es) pendiente(s)'),
                        );
                      },
                    ),
    );
  }
}

class _TorneoSolicitud {
  final int id;
  final String nombre;
  final int count;
  _TorneoSolicitud({required this.id, required this.nombre, required this.count});
}
