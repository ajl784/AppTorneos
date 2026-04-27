
import 'package:flutter/material.dart';
import 'package:front/state/jwt_storage.dart';
import 'package:front/state/auth_state.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/features/usuarios/data/usuarios_api.dart';
import 'package:front/features/usuarios/domain/usuario.dart';
import 'package:front/features/equipos/data/equipos_api.dart';
import 'package:front/features/equipos/domain/equipo.dart';
import 'package:front/features/categorias/widgets/categoria_network_avatar.dart';

// Platform imports
import 'package:flutter/foundation.dart' show kIsWeb;
// Only import dart:io if not web
// Only import dart:html if web
// These imports must be separated due to Dart restrictions
// ignore: uri_does_not_exist
import 'dart:io' as io;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'modificar_perfil_screen.dart';
import 'cambiar_contrasena_screen.dart';
import 'equipo_info.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/features/torneos/domain/torneo.dart';
import 'mitorneo_info.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({Key? key}) : super(key: key);

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Usuario? _usuario;
  ImageProvider? _profileImage;
  List<Equipo> _misEquipos = [];
  List<Torneo> _misTorneos = [];
  bool _loading = true;
  String? _error;
  // Eliminados controllers de edición, ahora solo se usan en pantallas separadas
  // For image
  bool _hasProfilePic = false;
  bool _profilePicLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }


  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final jwtUser = await JwtStorage.getUser();
      if (jwtUser == null) throw Exception('No hay usuario logueado');
      final int idUsuario = int.parse(jwtUser['id_usuario'].toString());

      // Obtener datos completos usuario
      final usuarioApi = UsuariosApi(baseUrl: ApiConfig.baseUrl);
      final userResp = await usuarioApi.getUsuarioById(idUsuario);

      // Foto de perfil
      ImageProvider? profileImage;
      bool hasProfilePic = false;
      try {
        final url = ApiConfig.baseUrl.replaceAll('/api/v1', '') + '/api/v1/usuarios/$idUsuario/profile-pic';
        if (userResp.fotoperfil != null) {
          profileImage = NetworkImage(url);
          hasProfilePic = true;
        } else {
          profileImage = null;
          hasProfilePic = false;
        }
      } catch (_) {
        profileImage = null;
        hasProfilePic = false;
      }

      // Mis equipos: usar la nueva API /api/v1/equipos/usuario/<idUsuario>
      final equiposApi = EquiposApi(baseUrl: ApiConfig.baseUrl);
      final equiposResp = await equiposApi.getEquiposByUsuario(idUsuario);
      final misEquipos = equiposResp.data;

      // Mis torneos: usar la API /api/v1/torneos?organizadorId=<idUsuario>
      final torneosApi = TorneosApi(baseUrl: ApiConfig.baseUrl);
      final torneosResp = await torneosApi.listTorneos(organizadorId: idUsuario);
      final misTorneos = torneosResp.data;

      setState(() {
        _usuario = userResp;
        _profileImage = profileImage;
        _misEquipos = misEquipos;
        _misTorneos = misTorneos;
        _hasProfilePic = hasProfilePic;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }


  // Navegación a pantallas de edición
  Future<void> _goToModificarPerfil() async {
    if (_usuario == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ModificarPerfilScreen(
          usuario: _usuario!,
          onProfileUpdated: () async {
            await _loadAll();
          },
        ),
      ),
    );
    // Forzar refresh siempre al volver
    await _loadAll();
  }

  Future<void> _goToCambiarContrasena() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CambiarContrasenaScreen(
          onPasswordChanged: () async {
            await _loadAll();
          },
        ),
      ),
    );
    // Forzar refresh siempre al volver
    await _loadAll();
  }

  Future<void> _pickProfileImage() async {
    setState(() { _profilePicLoading = true; });
    try {
      final token = await JwtStorage.getToken();
      if (token == null) throw Exception('No hay token');
      final api = UsuariosApi(baseUrl: ApiConfig.baseUrl);
      dynamic resp;
      if (kIsWeb) {
        // WEB: Usar file_picker (FilePicker.instance)
        final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
        if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
          setState(() { _profilePicLoading = false; });
          return;
        }
        final bytes = result.files.first.bytes!;
        resp = await api.uploadProfilePic(token, bytes);
      } else {
        // MÓVIL/ESCRITORIO: Usar image_picker
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked == null) {
          setState(() { _profilePicLoading = false; });
          return;
        }
        resp = await api.uploadProfilePic(token, io.File(picked.path));
      }
      // DEBUG: Mostrar respuesta completa del servidor
      // ignore: avoid_print
      print('Respuesta servidor uploadProfilePic:');
      print(resp);
      if (resp['ok'] == true) {
        await _loadAll();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto de perfil actualizada')));
      } else {
        // Mostrar respuesta completa en el error
        throw Exception('Error al subir foto. Respuesta: ' + resp.toString());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _profilePicLoading = false; });
    }
  }

  String _formatoFechasTorneo(String? inicio, String? fin) {
    if (inicio == null && fin == null) return '-';
    String? fechaIni = _formatoFechaCorta(inicio);
    String? fechaFin = _formatoFechaCorta(fin);
    if (fechaIni != null && fechaFin != null) {
      return '$fechaIni - $fechaFin';
    } else if (fechaIni != null) {
      return fechaIni;
    } else if (fechaFin != null) {
      return fechaFin;
    }
    return '-';
  }

  String? _formatoFechaCorta(String? fechaIso) {
    if (fechaIso == null) return null;
    try {
      final dt = DateTime.parse(fechaIso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteProfileImage() async {
    setState(() { _profilePicLoading = true; });
    try {
      final token = await JwtStorage.getToken();
      if (token == null) throw Exception('No hay token');
      final resp = await UsuariosApi(baseUrl: ApiConfig.baseUrl).deleteProfilePic(token);
      if (resp['ok'] == true) {
        await _loadAll();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto de perfil eliminada')));
      } else {
        throw Exception('Error al eliminar foto');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _profilePicLoading = false; });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await JwtStorage.deleteToken();
      AuthState.isLoggedIn.value = false;
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Foto de perfil
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: _profileImage,
                            child: _profileImage == null ? const Icon(Icons.person, size: 48) : null,
                          ),
                          if (_profilePicLoading)
                            const Positioned.fill(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          if (_hasProfilePic && !_profilePicLoading)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Eliminar foto de perfil',
                                onPressed: _deleteProfileImage,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _profilePicLoading ? null : _pickProfileImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Cambiar imagen de perfil'),
                      ),
                      const SizedBox(height: 24),
                      // Datos en texto plano
                      if (_usuario != null) ...[
                        _buildUserInfoRow('Nombre', _usuario!.nombre),
                        _buildUserInfoRow('Apellidos', _usuario!.apellidos),
                        _buildUserInfoRow('Nombre de usuario', _usuario!.nombreUsuario),
                        _buildUserInfoRow('Correo', _usuario!.correo),
                        _buildUserInfoRow('Fecha de nacimiento', _usuario!.fechanacimiento),
                        _buildUserInfoRow('Género', _usuario!.genero),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _goToModificarPerfil,
                        icon: const Icon(Icons.edit),
                        label: const Text('Modificar perfil'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _goToCambiarContrasena,
                        icon: const Icon(Icons.lock),
                        label: const Text('Cambiar contraseña'),
                      ),
                      const SizedBox(height: 32),
                      // Mis torneos
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Mis torneos', style: theme.textTheme.titleMedium),
                      ),
                      const SizedBox(height: 12),
                      if (_misTorneos.isEmpty)
                        const Text('No has creado ningún torneo.')
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Calcula el número de columnas según el ancho disponible
                            int crossAxisCount = (constraints.maxWidth / 260).floor();
                            if (crossAxisCount < 1) crossAxisCount = 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 120,
                              ),
                              itemCount: _misTorneos.length,
                              itemBuilder: (ctx, i) {
                                final torneo = _misTorneos[i];
                                return GestureDetector(
                                  onTap: () async {
                                    final updated = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => MiTorneoInfoScreen(
                                          torneo: torneo,
                                          onTorneoUpdated: _loadAll,
                                        ),
                                      ),
                                    );
                                    if (updated == true) await _loadAll();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        if (torneo.categoriaId != null)
                                          CategoriaNetworkAvatar(
                                            categoriaId: torneo.categoriaId!,
                                            baseUrl: ApiConfig.baseUrl,
                                            size: 42,
                                          )
                                        else
                                          CircleAvatar(
                                            radius: 21,
                                            backgroundColor:
                                                theme.colorScheme.surfaceContainerHighest,
                                            child: Icon(
                                              Icons.emoji_events,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                torneo.nombre,
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _formatoFechasTorneo(
                                                  torneo.fechaInicio,
                                                  torneo.fechaFin,
                                                ),
                                                style: theme.textTheme.bodySmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 32),
                      // Mis equipos
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Mis equipos', style: theme.textTheme.titleMedium),
                      ),
                      const SizedBox(height: 12),
                      if (_misEquipos.isEmpty)
                        const Text('No perteneces a ningún equipo.')
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = (constraints.maxWidth / 260).floor();
                            if (crossAxisCount < 1) crossAxisCount = 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 96,
                              ),
                              itemCount: _misEquipos.length,
                              itemBuilder: (ctx, i) {
                                final equipo = _misEquipos[i];
                                return GestureDetector(
                                  onTap: () async {
                                    final updated = await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => EquipoInfoScreen(
                                          equipo: equipo,
                                          onEquipoUpdated: _loadAll,
                                        ),
                                      ),
                                    );
                                    if (updated == true) await _loadAll();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        if (equipo.idCategoria != null)
                                          CategoriaNetworkAvatar(
                                            categoriaId: equipo.idCategoria!,
                                            baseUrl: ApiConfig.baseUrl,
                                            size: 36,
                                          )
                                        else
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor:
                                                theme.colorScheme.surfaceContainerHighest,
                                            child: Icon(
                                              Icons.groups,
                                              color: theme.colorScheme.primary,
                                              size: 18,
                                            ),
                                          ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                equipo.nombre,
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (equipo.categoriaNombre != null &&
                                                  equipo.categoriaNombre!.trim().isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  equipo.categoriaNombre!,
                                                  style: theme.textTheme.bodySmall,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? '-', overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
