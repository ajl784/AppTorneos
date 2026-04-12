import 'package:flutter/material.dart';
import 'package:front/features/equipos/domain/equipo.dart';

class EquipoInfoScreen extends StatefulWidget {
  final Equipo equipo;
  final VoidCallback? onEquipoUpdated;

  const EquipoInfoScreen({Key? key, required this.equipo, this.onEquipoUpdated}) : super(key: key);

  @override
  State<EquipoInfoScreen> createState() => _EquipoInfoScreenState();
}

class _EquipoInfoScreenState extends State<EquipoInfoScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _eloController;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.equipo.nombre);
    _descripcionController = TextEditingController(text: widget.equipo.descripcion ?? '');
    _eloController = TextEditingController(text: widget.equipo.elo?.toString() ?? '');
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
          ],
        ),
      ),
    );
  }
}
