import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:front/peticion/api_config.dart';

class AuthApi {
  final String baseUrl;
  final http.Client _client;

  AuthApi({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client();

  Uri _buildUri(String path) {
    final safePath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseUrl/$safePath');
  }

  Future<Map<String, dynamic>> register({
    required String correo,
    required String nombreUsuario,
    required String password,
  }) async {
    final uri = _buildUri('usuarios/register');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': correo,
        'nombre_usuario': nombreUsuario,
        'password': password,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    return decoded;
  }

  Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    final uri = _buildUri('usuarios/login');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': correo,
        'password': password,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    return decoded;
  }
}
