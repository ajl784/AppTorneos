import 'package:flutter/material.dart';
import 'package:front/features/torneos/domain/torneo.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/screens/perfil/gestion_solicitudes_inscripcion.dart';

class MiTorneoInfoScreen extends StatefulWidget {
  final Torneo torneo;
  final VoidCallback? onTorneoUpdated;

  const MiTorneoInfoScreen({
    Key? key,
    required this.torneo,
    this.onTorneoUpdated,
  }) : super(key: key);

  @override
  State<MiTorneoInfoScreen> createState() => _MiTorneoInfoScreenState();
}

class _MiTorneoInfoScreenState extends State<MiTorneoInfoScreen> {
  late Torneo _torneo;
  bool _editando = false;
  bool _cargando = false;
  final _formKey = GlobalKey<FormState>();
  // Campos editables
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _fechaInicioController;
  late TextEditingController _fechaFinController;
  late TextEditingController _estadoController;
  final List<String> _estados = ['inscripcion_abierta', 'en_curso', 'acabado'];
  late TextEditingController _participantesController;

  @override
  void initState() {
    super.initState();
    _torneo = widget.torneo;
    _nombreController = TextEditingController(text: _torneo.nombre);
    _descripcionController = TextEditingController(text: _torneo.descripcion ?? '');
    _fechaInicioController = TextEditingController(text: _torneo.fechaInicio ?? '');
    _fechaFinController = TextEditingController(text: _torneo.fechaFin ?? '');
    _estadoController = TextEditingController(text: _torneo.estado ?? '');
    _participantesController = TextEditingController(text: _torneo.participantesPorPartido?.toString() ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    _estadoController.dispose();
    _participantesController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _cargando = true; });
    try {
      final api = TorneosApi(baseUrl: ApiConfig.baseUrl);
      final updated = await api.updateTorneo(
        _torneo.id,
        TorneoUpdate(
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim(),
          fechaInicio: _fechaInicioController.text.trim().isEmpty ? null : _fechaInicioController.text.trim(),
          fechaFin: _fechaFinController.text.trim().isEmpty ? null : _fechaFinController.text.trim(),
          estado: _estadoController.text.trim().isEmpty ? null : _estadoController.text.trim(),
          limiteEquipos: int.tryParse(_participantesController.text.trim()),
        ),
      );
      setState(() {
        _torneo = updated;
        _editando = false;
      });
      if (widget.onTorneoUpdated != null) widget.onTorneoUpdated!();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Torneo actualizado')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _cargando = false; });
    }
  }

  Future<void> _eliminarTorneo() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar torneo?'),
        content: const Text('¿Seguro que quieres eliminar este torneo? Esta acción no se puede deshacer.'),
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
    if (confirmado == true) {
      setState(() { _cargando = true; });
      try {
        final api = TorneosApi(baseUrl: ApiConfig.baseUrl);
        final ok = await api.deleteTorneo(_torneo.id);
        if (ok) {
          if (widget.onTorneoUpdated != null) widget.onTorneoUpdated!();
          if (mounted) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Torneo eliminado')));
          }
        } else {
          throw Exception('No se pudo eliminar el torneo');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() { _cargando = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del torneo'),
        actions: [
          if (!_editando)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
              onPressed: () => setState(() => _editando = true),
            ),
          if (_editando)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancelar',
              onPressed: () => setState(() => _editando = false),
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: _editando ? _buildEditForm() : _buildDetails(),
            ),
    );
  }

  Widget _buildDetails() {
    return ListView(
      children: [
        Text(
          _torneo.nombre,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        _buildDetail('Descripción', _torneo.descripcion),
        _buildDetail('Fecha de inicio', _torneo.fechaInicio),
        _buildDetail('Fecha de fin', _torneo.fechaFin),
        _buildDetail('Estado', _torneo.estado),
        _buildDetail('Categoría', _torneo.categoriaNombre),
        _buildDetail('Tipo de torneo', _torneo.tipoTorneoNombre),
        _buildDetail('Participantes por partido', _torneo.participantesPorPartido?.toString()),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _generarBracketEliminacion,
          icon: const Icon(Icons.account_tree),
          label: const Text('Generar enfrentamientos'),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => GestionSolicitudesInscripcionScreen(torneoId: _torneo.id),
              ),
            );
          },
          icon: const Icon(Icons.group_add),
          label: const Text('Ver solicitudes de inscripción'),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => setState(() => _editando = true),
          icon: const Icon(Icons.edit),
          label: const Text('Modificar datos del torneo'),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _eliminarTorneo,
          icon: const Icon(Icons.delete),
          label: const Text('Eliminar torneo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descripcionController,
            decoration: const InputDecoration(labelText: 'Descripción'),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _fechaInicioController,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Fecha de inicio (YYYY-MM-DD)'),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _torneo.fechaInicio != null && _torneo.fechaInicio!.isNotEmpty
                    ? DateTime.tryParse(_torneo.fechaInicio!) ?? DateTime.now()
                    : DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                _fechaInicioController.text = picked.toIso8601String().substring(0, 10);
              }
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _fechaFinController,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Fecha de fin (YYYY-MM-DD)'),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _torneo.fechaFin != null && _torneo.fechaFin!.isNotEmpty
                    ? DateTime.tryParse(_torneo.fechaFin!) ?? DateTime.now()
                    : DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                _fechaFinController.text = picked.toIso8601String().substring(0, 10);
              }
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _estados.contains(_estadoController.text) ? _estadoController.text : null,
            decoration: const InputDecoration(labelText: 'Estado'),
            items: _estados
                .map((estado) => DropdownMenuItem(
                      value: estado,
                      child: Text(estado),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _estadoController.text = value;
                });
              }
            },
            validator: (v) => v == null || v.isEmpty ? 'Selecciona un estado' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _participantesController,
            decoration: const InputDecoration(labelText: 'Participantes por partido'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _guardarCambios,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _editando = false),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? '-', overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Future<void> _generarBracketEliminacion() async {
    setState(() { _cargando = true; });
    try {
      final api = TorneosApi(baseUrl: ApiConfig.baseUrl);
      await api.generarBracketEliminacion(_torneo.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bracket de eliminación generado')),
      );
      if (widget.onTorneoUpdated != null) widget.onTorneoUpdated!();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar bracket: $e')),
      );
    } finally {
      setState(() { _cargando = false; });
    }
  }
}
