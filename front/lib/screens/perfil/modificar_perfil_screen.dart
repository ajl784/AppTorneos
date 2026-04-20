import 'package:flutter/material.dart';
import 'package:front/features/usuarios/domain/usuario.dart';
import 'package:front/state/jwt_storage.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/features/usuarios/data/usuarios_api.dart';

class ModificarPerfilScreen extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback? onProfileUpdated;
  const ModificarPerfilScreen({Key? key, required this.usuario, this.onProfileUpdated}) : super(key: key);

  @override
  State<ModificarPerfilScreen> createState() => _ModificarPerfilScreenState();
}

class _ModificarPerfilScreenState extends State<ModificarPerfilScreen> {
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _nombreUsuarioController = TextEditingController();
  final _correoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  String? _genero;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nombreController.text = widget.usuario.nombre ?? '';
    _apellidosController.text = widget.usuario.apellidos ?? '';
    _nombreUsuarioController.text = widget.usuario.nombreUsuario ?? '';
    _correoController.text = widget.usuario.correo ?? '';
    _fechaNacimientoController.text = widget.usuario.fechanacimiento ?? '';
    _genero = widget.usuario.genero;
  }

  Future<void> _updateProfile() async {
    setState(() { _loading = true; });
    try {
      final token = await JwtStorage.getToken();
      if (token == null) throw Exception('No hay token');
      final payload = <String, dynamic>{
        'nombre': _nombreController.text,
        'apellidos': _apellidosController.text,
        'nombre_usuario': _nombreUsuarioController.text,
        'correo': _correoController.text,
        'fechanacimiento': _fechaNacimientoController.text,
        'genero': _genero,
      };
      payload.removeWhere((k, v) => v == null || v.toString().isEmpty);
      final resp = await UsuariosApi(baseUrl: ApiConfig.baseUrl).updateMe(token, payload);
      if (resp['ok'] == true) {
        if (widget.onProfileUpdated != null) widget.onProfileUpdated!();
        if (mounted) Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
      } else {
        throw Exception('Error al actualizar perfil');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modificar perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apellidosController,
                    decoration: const InputDecoration(labelText: 'Apellidos'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nombreUsuarioController,
                    decoration: const InputDecoration(labelText: 'Nombre de usuario'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _correoController,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _fechaNacimientoController,
                    decoration: const InputDecoration(labelText: 'Fecha de nacimiento (YYYY-MM-DD)'),
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _genero,
                    items: const [
                      DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                      DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                      DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                    ],
                    onChanged: (v) => setState(() => _genero = v),
                    decoration: const InputDecoration(labelText: 'Género'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _updateProfile,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
    );
  }
}
