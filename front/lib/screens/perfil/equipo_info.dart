import 'package:flutter/material.dart';
import 'package:front/api/api_exception.dart';
import 'package:front/features/equipos/data/equipos_api.dart';
import 'package:front/features/equipos/domain/equipo.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/state/jwt_storage.dart';

class EquipoInfoScreen extends StatefulWidget {
  final Equipo equipo;
  final VoidCallback? onEquipoUpdated;

  const EquipoInfoScreen({super.key, required this.equipo, this.onEquipoUpdated});

  @override
  State<EquipoInfoScreen> createState() => _EquipoInfoScreenState();
}

class _EquipoInfoScreenState extends State<EquipoInfoScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _eloController;
  late final EquiposApi _equiposApi;

  bool _editMode = false;
  bool _loadingSolicitudes = true;
  bool _hasPermisoGestion = false;
  List<Map<String, dynamic>> _solicitudes = const [];
  String? _errorSolicitudes;

  @override
  void initState() {
    super.initState();
    _equiposApi = EquiposApi(baseUrl: ApiConfig.baseUrl);
    _nombreController = TextEditingController(text: widget.equipo.nombre);
    _descripcionController = TextEditingController(text: widget.equipo.descripcion ?? '');
    _eloController = TextEditingController(text: widget.equipo.elo?.toString() ?? '');
    _loadSolicitudes();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _eloController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _editMode = !_editMode;
    });
  }

  Future<void> _saveChanges() async {
    // Aquí deberías llamar a la API para guardar los cambios
    // Por ahora solo simula el guardado
    setState(() {
      _editMode = false;
    });
    if (widget.onEquipoUpdated != null) widget.onEquipoUpdated!();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipo actualizado')));
  }

  String _descripcionSolicitud(Map<String, dynamic> solicitud) {
    final respuesta = solicitud['respuesta'];
    if (respuesta is Map && respuesta['descripcion'] != null) {
      return respuesta['descripcion'].toString();
    }
    return 'Sin descripción';
  }

  Future<void> _loadSolicitudes() async {
    setState(() {
      _loadingSolicitudes = true;
      _errorSolicitudes = null;
    });

    final token = await JwtStorage.getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _loadingSolicitudes = false;
        _errorSolicitudes = 'Debes iniciar sesión';
      });
      return;
    }

    try {
      final solicitudes = await _equiposApi.listSolicitudesIngresoEquipo(
        idEquipo: widget.equipo.idEquipo,
        token: token,
        estado: 'pendiente',
      );

      if (!mounted) return;
      setState(() {
        _solicitudes = solicitudes;
        _loadingSolicitudes = false;
        _hasPermisoGestion = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingSolicitudes = false;
        _hasPermisoGestion = false;
        _errorSolicitudes = e.statusCode == 403
            ? 'Solo el entrenador del equipo puede gestionar solicitudes.'
            : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingSolicitudes = false;
        _hasPermisoGestion = false;
        _errorSolicitudes = 'Error al cargar solicitudes';
      });
    }
  }

  Future<void> _decidirSolicitud(int idSolicitudEquipo, bool aceptar) async {
    final token = await JwtStorage.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión.')),
      );
      return;
    }

    try {
      await _equiposApi.decidirSolicitudIngresoEquipo(
        idSolicitudEquipo: idSolicitudEquipo,
        aceptar: aceptar,
        token: token,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(aceptar ? 'Solicitud aceptada' : 'Solicitud rechazada')),
      );
      await _loadSolicitudes();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo responder: ${e.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo responder la solicitud.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del equipo'),
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.close : Icons.edit),
            onPressed: _toggleEdit,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              enabled: _editMode,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              enabled: _editMode,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _eloController,
              decoration: const InputDecoration(labelText: 'ELO'),
              enabled: _editMode,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            if (_editMode)
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text('Guardar cambios'),
              ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text('Solicitudes de ingreso', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_loadingSolicitudes)
              const Center(child: CircularProgressIndicator())
            else if (!_hasPermisoGestion)
              Text(_errorSolicitudes ?? 'No tienes permisos para gestionar solicitudes.')
            else if (_solicitudes.isEmpty)
              const Text('No hay solicitudes pendientes.')
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _solicitudes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final solicitud = _solicitudes[index];
                    final idSolicitud = int.tryParse(
                      (solicitud['id_solicitud_equipo'] ?? '').toString(),
                    );
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              solicitud['nombre_usuario']?.toString() ?? 'Usuario',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(solicitud['correo']?.toString() ?? '-'),
                            const SizedBox(height: 8),
                            Text('Descripción: ${_descripcionSolicitud(solicitud)}'),
                            const SizedBox(height: 10),
                            if (idSolicitud != null)
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _decidirSolicitud(idSolicitud, true),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Aceptar'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _decidirSolicitud(idSolicitud, false),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Rechazar'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
