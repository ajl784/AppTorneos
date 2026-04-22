import 'package:flutter/material.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/features/categorias/data/categorias_api.dart';
import 'package:front/features/categorias/domain/categoria.dart';
import 'package:front/features/categorias/widgets/categoria_icon_avatar.dart';
import 'package:front/features/equipos/data/equipos_api.dart';
import 'package:front/features/equipos/domain/equipo.dart';
import 'package:front/state/jwt_storage.dart';

class UnirseEquipoScreen extends StatefulWidget {
  const UnirseEquipoScreen({super.key});

  @override
  State<UnirseEquipoScreen> createState() => _UnirseEquipoScreenState();
}

class _UnirseEquipoScreenState extends State<UnirseEquipoScreen> {
  late final CategoriasApi _categoriasApi;
  late final EquiposApi _equiposApi;

  List<Categoria> _categorias = const [];
  List<Equipo> _equipos = const [];
  Set<int> _misEquipos = <int>{};
  int? _idCategoria;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _categoriasApi = CategoriasApi(baseUrl: ApiConfig.baseUrl);
    _equiposApi = EquiposApi(baseUrl: ApiConfig.baseUrl);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await JwtStorage.getUser();
      final idUsuarioRaw = user?['id_usuario'];
      final idUsuario = idUsuarioRaw is int
          ? idUsuarioRaw
          : int.tryParse(idUsuarioRaw?.toString() ?? '');
      if (idUsuario == null) {
        throw Exception('No se pudo obtener el usuario actual');
      }

      final categoriasRes = await _categoriasApi.listCategorias(limit: 200, offset: 0);
      final categorias = categoriasRes.data;

      final misEquiposRes = await _equiposApi.getEquiposByUsuario(idUsuario);
      final misEquipos = misEquiposRes.data.map((e) => e.idEquipo).toSet();

      setState(() {
        _categorias = categorias;
        _idCategoria = categorias.isNotEmpty ? categorias.first.idCategoria : null;
        _misEquipos = misEquipos;
      });

      await _loadEquipos();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadEquipos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _equiposApi.listEquipos(
        limit: 200,
        offset: 0,
        categoriaId: _idCategoria,
      );

      final equiposDisponibles = res.data
          .where((e) => !_misEquipos.contains(e.idEquipo))
          .toList(growable: false);

      setState(() {
        _equipos = equiposDisponibles;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _solicitarIngreso(Equipo equipo) async {
    final token = await JwtStorage.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para solicitar ingreso.')),
      );
      return;
    }

    final controller = TextEditingController();
    final descripcion = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Solicitud para ${equipo.nombre}'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              hintText: 'Explica por qué quieres unirte al equipo',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La descripción es obligatoria.')),
                  );
                  return;
                }
                Navigator.of(context).pop(value);
              },
              child: const Text('Enviar solicitud'),
            ),
          ],
        );
      },
    );

    if (descripcion == null || descripcion.trim().isEmpty) {
      return;
    }

    try {
      await _equiposApi.solicitarIngresoEquipo(
        idEquipo: equipo.idEquipo,
        descripcion: descripcion,
        token: token,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitud enviada a ${equipo.nombre}.')),
      );

      await _loadEquipos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar la solicitud: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unirse a un equipo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _idCategoria,
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
              onChanged: (value) async {
                setState(() => _idCategoria = value);
                await _loadEquipos();
              },
              decoration: const InputDecoration(
                labelText: 'Filtrar por categoría',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(child: Center(child: Text(_error!)))
            else if (_equipos.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No hay equipos disponibles para esta categoría.'),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _equipos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final equipo = _equipos[index];
                    return Card(
                      child: ListTile(
                        title: Text(equipo.nombre),
                        subtitle: Text(equipo.descripcion ?? 'Sin descripción'),
                        trailing: ElevatedButton(
                          onPressed: () => _solicitarIngreso(equipo),
                          child: const Text('Solicitar ingreso'),
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
