import 'package:flutter/material.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/features/equipos/data/equipos_api.dart';
import 'package:front/features/equipos/domain/equipo.dart';

class GestionSolicitudesInscripcionScreen extends StatefulWidget {
  final int torneoId;
  const GestionSolicitudesInscripcionScreen({Key? key, required this.torneoId}) : super(key: key);

  @override
  State<GestionSolicitudesInscripcionScreen> createState() => _GestionSolicitudesInscripcionScreenState();
}

class _GestionSolicitudesInscripcionScreenState extends State<GestionSolicitudesInscripcionScreen> {
  bool _cargando = true;
  List<dynamic> _solicitudes = [];
  Map<String, dynamic>? _formulario;
  String? _error;
  Map<int, Equipo> _equipos = {};

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final torneosApi = TorneosApi(baseUrl: ApiConfig.baseUrl);
      final equiposApi = EquiposApi(baseUrl: ApiConfig.baseUrl);
        // Obtener solicitudes pendientes
        final solicitudes = await torneosApi.getSolicitudesInscripcion(widget.torneoId, estado: 'pendiente');
      // Obtener formulario (puede no existir)
      Map<String, dynamic>? formulario;
      try {
        final formObj = await torneosApi.getFormularioTorneo(widget.torneoId);
        formulario = formObj.formulario as Map<String, dynamic>?;
      } catch (_) {
        formulario = null;
      }
      // Obtener datos básicos de los equipos
      Map<int, Equipo> equipos = {};
      for (final s in solicitudes) {
        final idEquipo = int.tryParse(s['id_equipo']?.toString() ?? '');
        if (idEquipo != null && !equipos.containsKey(idEquipo)) {
          try {
            final equipo = await equiposApi.getEquipoById(idEquipo);
            equipos[idEquipo] = equipo;
          } catch (_) {}
        }
      }
      setState(() {
        _solicitudes = solicitudes;
        _formulario = formulario;
        _equipos = equipos;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar solicitudes: $e';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes de inscripción')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _solicitudes.isEmpty
                  ? const Center(child: Text('No hay solicitudes pendientes.'))
                  : ListView.builder(
                      itemCount: _solicitudes.length,
                      itemBuilder: (context, i) {
                        final solicitud = _solicitudes[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildSolicitud(solicitud),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildSolicitud(Map<String, dynamic> solicitud) {
    final idEquipo = int.tryParse(solicitud['id_equipo']?.toString() ?? '');
    final equipo = idEquipo != null ? _equipos[idEquipo] : null;
    final fecha = solicitud['fecha'] ?? '-';
    final respuesta = solicitud['respuesta'] as Map<String, dynamic>?;
    final idParticipacionEquipo = int.tryParse(solicitud['id_participacion_equipo']?.toString() ?? '');
    final List<Widget> children = [
      Text('Equipo: ${equipo?.nombre ?? solicitud['equipo_nombre'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
      if (equipo?.descripcion != null && equipo?.descripcion!.isNotEmpty == true)
        Text('Descripción: ${equipo?.descripcion}'),
      if (equipo?.elo != null)
        Text('ELO: ${equipo?.elo}'),
      Text('Fecha: $fecha'),
    ];
    // Mostrar respuestas al formulario si existen y hay formulario
    if (_formulario != null && respuesta != null) {
      final preguntas = _formulario?['preguntas'] as List<dynamic>?;
      if (preguntas != null) {
        int idx = 1;
        for (final pregunta in preguntas) {
          final label = pregunta['label'] ?? 'Pregunta';
          final key = 'q$idx';
          final value = respuesta[key]?.toString() ?? '-';
          children.add(Text('$label: $value'));
          idx++;
        }
      }
    }
    // Botones aceptar/denegar
    if (idParticipacionEquipo != null) {
      children.add(const SizedBox(height: 12));
      children.add(Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Aceptar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => _responderSolicitud(idParticipacionEquipo, true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text('Denegar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _responderSolicitud(idParticipacionEquipo, false),
            ),
          ),
        ],
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Future<void> _responderSolicitud(int idParticipacionEquipo, bool aceptar) async {
    setState(() { _cargando = true; });
    try {
      final torneosApi = TorneosApi(baseUrl: ApiConfig.baseUrl);
      await torneosApi.responderSolicitudInscripcion(
        idParticipacionEquipo: idParticipacionEquipo,
        aceptar: aceptar,
      );
      // Recargar solicitudes tras responder
      await _cargarSolicitudes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(aceptar ? 'Solicitud aceptada' : 'Solicitud denegada')),
      );
    } catch (e) {
      setState(() { _cargando = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al responder: $e')),
      );
    }
  }
}
