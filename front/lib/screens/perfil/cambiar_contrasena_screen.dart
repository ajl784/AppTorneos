import 'package:flutter/material.dart';
import 'package:front/state/jwt_storage.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/features/usuarios/data/usuarios_api.dart';

class CambiarContrasenaScreen extends StatefulWidget {
  final VoidCallback? onPasswordChanged;
  const CambiarContrasenaScreen({Key? key, this.onPasswordChanged}) : super(key: key);

  @override
  State<CambiarContrasenaScreen> createState() => _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  bool _loading = false;

  Future<void> _updatePassword() async {
    if (_passwordController.text != _password2Controller.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contraseñas no coinciden')));
      return;
    }
    setState(() { _loading = true; });
    try {
      final token = await JwtStorage.getToken();
      if (token == null) throw Exception('No hay token');
      final payload = <String, dynamic>{
        'password': _passwordController.text,
      };
      final resp = await UsuariosApi(baseUrl: ApiConfig.baseUrl).updateMe(token, payload);
      if (resp['ok'] == true) {
        _passwordController.clear();
        _password2Controller.clear();
        if (widget.onPasswordChanged != null) widget.onPasswordChanged!();
        if (mounted) Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
      } else {
        throw Exception('Error al actualizar contraseña');
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
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password2Controller,
                    decoration: const InputDecoration(labelText: 'Repetir nueva contraseña'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _updatePassword,
                    icon: const Icon(Icons.save),
                    label: const Text('Cambiar contraseña'),
                  ),
                ],
              ),
            ),
    );
  }
}
