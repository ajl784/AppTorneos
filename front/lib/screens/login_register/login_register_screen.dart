import 'package:flutter/material.dart';

import 'package:front/state/auth_state.dart';
import 'package:front/peticion/auth_api.dart';
import 'package:front/peticion/api_config.dart';

import 'package:front/state/jwt_storage.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
    Future<void> _handleLogin() async {
      final correo = emailController.text.trim();
      final password = passwordController.text;
      if (correo.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Introduce correo y contraseña.')),
        );
        return;
      }
      try {
        final result = await _authApi.login(correo: correo, password: password);
        if (result['ok'] == true && result['data'] != null) {
          final token = result['data']['token'] as String?;
          final usuario = result['data']['usuario'] as Map<String, dynamic>?;
          if (token != null && usuario != null) {
            // Guardar token y usuario
            // ignore: use_build_context_synchronously
            await Future.wait([
              // ignore: use_build_context_synchronously
              JwtStorage.saveToken(token),
              JwtStorage.saveUser(usuario),
            ]);
            AuthState.isLoggedIn.value = true;
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        } else {
          final msg = result['error']?['message'] ?? 'Credenciales inválidas';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  final AuthApi _authApi = AuthApi(baseUrl: ApiConfig.baseUrl);
  bool isLogin = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final correo = emailController.text.trim();
    final nombreUsuario = usernameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    if (nombreUsuario.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre de usuario es obligatorio.')),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }
    try {
      final result = await _authApi.register(
        correo: correo,
        nombreUsuario: nombreUsuario,
        password: password,
      );
      if (result['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta registrada, ahora puedes iniciar sesión.'),
          ),
        );
        setState(() {
          isLogin = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']?.toString() ?? 'Error desconocido.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isLogin) ...[
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Nombre de usuario'),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            if (!isLogin) ...[
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña',
                ),
                obscureText: true,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (isLogin) {
                  await _handleLogin();
                } else {
                  await _handleRegister();
                }
              },
              child: Text(isLogin ? 'Iniciar sesión' : 'Registrarse'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                });
              },
              child: Text(
                isLogin
                    ? '¿No tienes cuenta? Regístrate'
                    : '¿Ya tienes cuenta? Inicia sesión',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
