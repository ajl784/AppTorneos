

import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:http_parser/http_parser.dart' as http_parser;

import 'package:front/api/api_response.dart';
import 'package:front/api/app_torneos_api_client.dart';
import 'package:front/features/usuarios/domain/usuario.dart';

class UsuariosApi {
  final AppTorneosApiClient _api;

  UsuariosApi({required String baseUrl, http.Client? client})
    : _api = AppTorneosApiClient(baseUrl: baseUrl, client: client);

  Future<ApiResponse<List<Usuario>>> listUsuarios({
    int? limit,
    int? offset,
    String? q,
  }) async {
    final res = await _api.getRaw(
      '/usuarios',
      queryParameters: {
        'limit': limit?.toString(),
        'offset': offset?.toString(),
        'q': q,
      },
    );

    final data = res.data;
    if (data is! List) {
      throw const FormatException('Respuesta inesperada (usuarios no es List)');
    }

    final usuarios = data
        .whereType<Map>()
        .map((item) => Usuario.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    return ApiResponse<List<Usuario>>(data: usuarios, meta: res.meta);
  }

  Future<Usuario> getUsuarioById(int idUsuario) async {
    final res = await _api.getRaw('/usuarios/$idUsuario');
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (usuario no es Map)');
    }

    return Usuario.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Usuario> createUsuario(UsuarioCreate payload) async {
    final res = await _api.postRaw('/usuarios', body: payload.toJson());
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (usuario no es Map)');
    }

    return Usuario.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Usuario> updateUsuario(int idUsuario, UsuarioUpdate payload) async {
    final res = await _api.putRaw(
      '/usuarios/$idUsuario',
      body: payload.toJson(),
    );
    final data = res.data;
    if (data is! Map) {
      throw const FormatException('Respuesta inesperada (usuario no es Map)');
    }

    return Usuario.fromJson(Map<String, dynamic>.from(data));
  }

  Future<bool> deleteUsuario(int idUsuario) async {
    final res = await _api.deleteRaw('/usuarios/$idUsuario');
    final data = res.data;

    if (data is Map) {
      final deleted = data['deleted'];
      if (deleted is bool) return deleted;
    }

    return true;
  }
  /// Actualiza el usuario autenticado (me) con JWT
  Future<Map<String, dynamic>> updateMe(String token, Map<String, dynamic> payload) async {
    final res = await _api.putRaw(
      '/usuarios/me',
      body: payload,
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.data is Map<String, dynamic> ? Map<String, dynamic>.from(res.data) : {};
  }

  /// Sube la foto de perfil del usuario autenticado (me) con JWT
  /// Admite tanto File (mobile/desktop) como Uint8List (web)
  Future<Map<String, dynamic>> uploadProfilePic(String token, dynamic fileOrBytes) async {
    final uri = _api.buildUri('/usuarios/me/profile-pic');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    if (kIsWeb) {
      // fileOrBytes is Uint8List
      final bytes = fileOrBytes as Uint8List;
      request.files.add(
        http.MultipartFile.fromBytes(
          'foto',
          bytes,
          filename: 'profile_pic.png',
          contentType: http_parser.MediaType('image', 'png'),
        ),
      );
    } else {
      // fileOrBytes is File
      final file = fileOrBytes as io.File;
      request.files.add(await http.MultipartFile.fromPath('foto', file.path));
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    // LOG: Mostrar status, headers y body de la respuesta
    // ignore: avoid_print
    print('uploadProfilePic: statusCode = \\${response.statusCode}');
    print('uploadProfilePic: headers = \\${response.headers}');
    print('uploadProfilePic: body = \\${response.body}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al subir foto: status=\\${response.statusCode}, body=\\${response.body}');
    }
    final decoded = AppTorneosApiClient.tryDecodeJson(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {};
  }

  /// Elimina la foto de perfil del usuario autenticado (me) con JWT
  Future<Map<String, dynamic>> deleteProfilePic(String token) async {
    final res = await _api.deleteRaw(
      '/usuarios/me/profile-pic',
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.data is Map<String, dynamic> ? Map<String, dynamic>.from(res.data) : {};
  }
}
