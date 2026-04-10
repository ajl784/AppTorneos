import 'package:flutter/material.dart';
import 'package:front/state/jwt_storage.dart';
import 'package:front/state/auth_state.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await JwtStorage.getUser();
    setState(() {
      _user = user;
    });
  }

  Future<void> _logout() async {
    await JwtStorage.deleteToken();
    AuthState.isLoggedIn.value = false;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: _user == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('ID: ${_user?['id_usuario'] ?? ''}'),
                  Text('Correo: ${_user?['correo'] ?? ''}'),
                  Text('Nombre de usuario: ${_user?['nombre_usuario'] ?? ''}'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ),
      ),
    );
  }
}
