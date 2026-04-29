import 'package:flutter/material.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/features/categorias/data/categorias_api.dart';
import 'package:front/features/categorias/domain/categoria.dart';
import 'package:front/features/categorias/widgets/categoria_icon_avatar.dart';
import 'package:front/features/equipos/data/equipos_api.dart';
import 'package:front/features/equipos/domain/equipo.dart';
import 'package:front/api/api_exception.dart';
import 'package:front/state/jwt_storage.dart';

class CrearEquipoScreen extends StatefulWidget {
  const CrearEquipoScreen({super.key});

  @override
  State<CrearEquipoScreen> createState() => _CrearEquipoScreenState();
}

class _CrearEquipoScreenState extends State<CrearEquipoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  List<Categoria> _categorias = const [];
  int? _categoriaSeleccionada;
  String? _errorCategorias;
  bool _enviando = false;
  bool _cargandoCategorias = true;

  late final EquiposApi _equiposApi;
  late final CategoriasApi _categoriasApi;

  @override
  void initState() {
    super.initState();
    _equiposApi = EquiposApi(baseUrl: ApiConfig.baseUrl);
    _categoriasApi = CategoriasApi(baseUrl: ApiConfig.baseUrl);
    _cargarCategorias();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    setState(() {
      _cargandoCategorias = true;
      _errorCategorias = null;
    });

    try {
      final res = await _categoriasApi.listCategorias(limit: 200, offset: 0);
      final categorias = res.data;
      setState(() {
        _categorias = categorias;
        _categoriaSeleccionada = categorias.isNotEmpty
            ? categorias.first.idCategoria
            : null;
        _cargandoCategorias = false;
      });
    } catch (e) {
      setState(() {
        _errorCategorias = 'No se pudieron cargar las categorías';
        _cargandoCategorias = false;
      });
    }
  }

  void _crearEquipo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría para el equipo.')),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      final user = await JwtStorage.getUser();
      final idUsuarioRaw = user?['id_usuario'];
      final idUsuario = idUsuarioRaw is int
          ? idUsuarioRaw
          : int.tryParse(idUsuarioRaw?.toString() ?? '');

      final equipo = await _equiposApi.createEquipo(
        EquipoCreate(
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim(),
          idCategoria: _categoriaSeleccionada!,
          idUsuario: idUsuario,
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
    if (_cargandoCategorias) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
              if (_errorCategorias != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_errorCategorias!, style: const TextStyle(color: Colors.red)),
                ),
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
              DropdownButtonFormField<int>(
                initialValue: _categoriaSeleccionada,
                items: _categorias
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: c.idCategoria,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CategoriaIconAvatar(categoria: c, baseUrl: ApiConfig.baseUrl, size: 24),
                            const SizedBox(width: 8),
                            Flexible(child: Text(c.nombre)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Categoría del equipo',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => _categoriaSeleccionada = value);
                },
                validator: (value) => value == null ? 'Selecciona una categoría' : null,
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
