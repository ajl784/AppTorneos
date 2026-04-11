import 'package:flutter/material.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/features/equipos/data/equipos_api.dart';
import 'package:front/features/equipos/domain/equipo.dart';
import 'package:front/api/api_exception.dart';

class CrearEquipoScreen extends StatefulWidget {
  const CrearEquipoScreen({super.key});

  @override
  State<CrearEquipoScreen> createState() => _CrearEquipoScreenState();
}

class _CrearEquipoScreenState extends State<CrearEquipoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  bool _enviando = false;

  late final EquiposApi _equiposApi;

  @override
  void initState() {
    super.initState();
    _equiposApi = EquiposApi(baseUrl: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _crearEquipo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final equipo = await _equiposApi.createEquipo(
        EquipoCreate(
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Equipo "${equipo.nombre}" creado correctamente.')),
      );
      Navigator.of(context).pop(equipo);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear equipo: \\${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error inesperado al crear equipo.')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear equipo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del equipo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Introduce un nombre' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Introduce una descripción' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _enviando ? null : _crearEquipo,
                child: _enviando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear equipo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
