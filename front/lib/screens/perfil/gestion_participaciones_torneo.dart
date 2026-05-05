import 'package:flutter/material.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/features/equipos/data/equipos_api.dart';
import 'package:front/features/equipos/domain/equipo.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/state/jwt_storage.dart';

class GestionParticipacionesTorneoScreen extends StatefulWidget {
  final int torneoId;
  final String torneoNombre;
  final VoidCallback? onParticipacionesUpdated;

  const GestionParticipacionesTorneoScreen({
    Key? key,
    required this.torneoId,
    required this.torneoNombre,
    this.onParticipacionesUpdated,
  }) : super(key: key);

  @override
  State<GestionParticipacionesTorneoScreen> createState() =>
      _GestionParticipacionesTorneoScreenState();
}

class _GestionParticipacionesTorneoScreenState
    extends State<GestionParticipacionesTorneoScreen> {
  late final TorneosApi _torneosApi = TorneosApi(baseUrl: ApiConfig.baseUrl);
  late final EquiposApi _equiposApi = EquiposApi(baseUrl: ApiConfig.baseUrl);

  bool _cargando = true;
  List<Map<String, dynamic>> _participaciones = [];
  Map<int, Equipo> _equipos = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarParticipaciones();
  }

  Future<void> _cargarParticipaciones() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      // Obtener participaciones del torneo
      final participaciones =
          await _torneosApi.getParticipacionesTorneo(widget.torneoId);

      // Cargar datos de equipos
      Map<int, Equipo> equipos = {};
      for (final p in participaciones) {
        final idEquipo = int.tryParse(p['id_equipo']?.toString() ?? '');
        if (idEquipo != null && !equipos.containsKey(idEquipo)) {
          try {
            final equipo = await _equiposApi.getEquipoById(idEquipo);
            equipos[idEquipo] = equipo;
          } catch (e) {
            debugPrint('Error cargando equipo $idEquipo: $e');
          }
        }
      }

      setState(() {
        _participaciones = participaciones;
        _equipos = equipos;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _eliminarParticipacion(
    int idParticipacionEquipo,
    String nombreEquipo,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar participación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a "$nombreEquipo" del torneo?\n\n'
          'Se eliminarán automáticamente todos los partidos relacionados y avanzará el bracket si aplica.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      final token = await JwtStorage.getToken();
      await _torneosApi.deleteParticipacion(
        idParticipacionEquipo,
        token: token,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Participación de "$nombreEquipo" eliminada')),
      );
      if (widget.onParticipacionesUpdated != null) {
        widget.onParticipacionesUpdated!();
      }
      _cargarParticipaciones();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Equipos inscritos: ${widget.torneoNombre}'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarParticipaciones,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _participaciones.isEmpty
                  ? const Center(
                      child: Text('No hay equipos inscritos en este torneo'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _participaciones.length,
                      itemBuilder: (ctx, idx) {
                        final p = _participaciones[idx];
                        final idParticipacionEquipo =
                            int.tryParse(p['id_participacion_equipo']?.toString() ?? '') ?? 0;
                        final idEquipo =
                            int.tryParse(p['id_equipo']?.toString() ?? '') ?? 0;
                        final equipo = _equipos[idEquipo];
                        final estado = p['estado'] ?? 'desconocido';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.sports_soccer),
                            title: Text(equipo?.nombre ?? 'Equipo $idEquipo'),
                            subtitle: Text('Estado: $estado'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Eliminar equipo del torneo',
                              onPressed: () => _eliminarParticipacion(
                                idParticipacionEquipo,
                                equipo?.nombre ?? 'Equipo',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
