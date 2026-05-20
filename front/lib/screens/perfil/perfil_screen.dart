import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:front/state/jwt_storage.dart';
import 'package:front/state/auth_state.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/features/usuarios/data/usuarios_api.dart';
import 'package:front/features/usuarios/domain/usuario.dart';
import 'package:front/features/equipos/data/equipos_api.dart';
import 'package:front/features/equipos/domain/equipo.dart';
import 'package:front/features/equipos/widgets/equipo_network_avatar.dart';
import 'package:front/features/categorias/widgets/categoria_network_avatar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'modificar_perfil_screen.dart';
import 'cambiar_contrasena_screen.dart';
import 'equipo_info.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/features/torneos/domain/torneo.dart';
import 'mitorneo_info.dart';
import 'gestion_invitaciones.dart';

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

      final usuarioApi = UsuariosApi(baseUrl: ApiConfig.baseUrl);
      final userResp = await usuarioApi.getUsuarioById(idUsuario);

      ImageProvider? profileImage;
      bool hasProfilePic = false;
      try {
        final url = '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}/api/v1/usuarios/$idUsuario/profile-pic';
        if (userResp.fotoperfil != null) {
          profileImage = NetworkImage(url);
          hasProfilePic = true;
        }
      } catch (_) {}

      final equiposApi = EquiposApi(baseUrl: ApiConfig.baseUrl);
      final equiposResp = await equiposApi.getEquiposByUsuario(idUsuario);

      final torneosApi = TorneosApi(baseUrl: ApiConfig.baseUrl);
      final torneosResp = await torneosApi.listTorneos(organizadorId: idUsuario);

      setState(() {
        _usuario = userResp;
        _profileImage = profileImage;
        _misEquipos = equiposResp.data;
        _misTorneos = torneosResp.data;
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

  Future<void> _goToModificarPerfil() async {
    if (_usuario == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ModificarPerfilScreen(
          usuario: _usuario!,
          onProfileUpdated: _loadAll,
        ),
      ),
    );
    await _loadAll();
  }

  Future<void> _goToCambiarContrasena() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CambiarContrasenaScreen(
          onPasswordChanged: _loadAll,
        ),
      ),
    );
    await _loadAll();
  }

  void _goToGestionInvitaciones() {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const GestionInvitacionesScreen()));
  }

  Future<void> _pickProfileImage() async {
    setState(() => _profilePicLoading = true);
    try {
      final token = await JwtStorage.getToken();
      if (token == null) throw Exception('No hay token');
      final api = UsuariosApi(baseUrl: ApiConfig.baseUrl);
      dynamic resp;
      
      if (kIsWeb) {
        final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
        if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
          setState(() => _profilePicLoading = false);
          return;
        }
        resp = await api.uploadProfilePic(token, result.files.first.bytes!);
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked == null) {
          setState(() => _profilePicLoading = false);
          return;
        }
        resp = await api.uploadProfilePic(token, io.File(picked.path));
      }
      
      if (resp['ok'] == true) {
        await _loadAll();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto de perfil actualizada')));
      } else {
        throw Exception('Error al subir foto.');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _profilePicLoading = false);
    }
  }

  Future<void> _deleteProfileImage() async {
    setState(() => _profilePicLoading = true);
    try {
      final token = await JwtStorage.getToken();
      if (token == null) throw Exception('No hay token');
      final resp = await UsuariosApi(baseUrl: ApiConfig.baseUrl).deleteProfilePic(token);
      if (resp['ok'] == true) {
        await _loadAll();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto de perfil eliminada')));
      } else {
        throw Exception('Error al eliminar foto');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _profilePicLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
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

  String _formatoFechasTorneo(String? inicio, String? fin) {
    if (inicio == null && fin == null) return '-';
    String? fechaIni = _formatoFechaCorta(inicio);
    String? fechaFin = _formatoFechaCorta(fin);
    if (fechaIni != null && fechaFin != null) return '$fechaIni - $fechaFin';
    return fechaIni ?? fechaFin ?? '-';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 280.0,
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.colorScheme.primaryContainer,
                                theme.colorScheme.surface,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                    backgroundImage: _profileImage,
                                    child: _profileImage == null 
                                      ? Icon(Icons.person, size: 60, color: theme.colorScheme.onSurfaceVariant) 
                                      : null,
                                  ),
                                  if (_profilePicLoading)
                                    const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: theme.colorScheme.surface, width: 3),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                      onPressed: _profilePicLoading ? null : _pickProfileImage,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ),
                                ],
                              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                              const SizedBox(height: 16),
                              if (_usuario != null) ...[
                                Text(
                                  '${_usuario!.nombre} ${_usuario!.apellidos}'.trim().isEmpty 
                                    ? _usuario!.nombreUsuario 
                                    : '${_usuario!.nombre} ${_usuario!.apellidos}',
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                ).animate().fadeIn(delay: 200.ms),
                                Text(
                                  '@${_usuario!.nombreUsuario}',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                                ).animate().fadeIn(delay: 300.ms),
                              ]
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        if (_hasProfilePic && !_profilePicLoading)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            tooltip: 'Eliminar foto',
                            onPressed: _deleteProfileImage,
                          ),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: _logout,
                          tooltip: 'Cerrar sesión',
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick Actions
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _ActionChip(
                                  icon: Icons.edit_outlined,
                                  label: 'Editar Perfil',
                                  onTap: _goToModificarPerfil,
                                ),
                                _ActionChip(
                                  icon: Icons.lock_outline,
                                  label: 'Contraseña',
                                  onTap: _goToCambiarContrasena,
                                ),
                                _ActionChip(
                                  icon: Icons.mail_outline,
                                  label: 'Invitaciones',
                                  onTap: _goToGestionInvitaciones,
                                ),
                              ],
                            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                            
                            const SizedBox(height: 32),
                            
                            // User Details Card
                            Text('Información Personal', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Card(
                              margin: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  _InfoTile(icon: Icons.email_outlined, title: 'Correo', subtitle: _usuario?.correo),
                                  const Divider(height: 1),
                                  _InfoTile(icon: Icons.cake_outlined, title: 'Fecha de nacimiento', subtitle: _formatoFechaCorta(_usuario?.fechanacimiento) ?? '-'),
                                  const Divider(height: 1),
                                  _InfoTile(icon: Icons.person_outline, title: 'Género', subtitle: _usuario?.genero ?? '-'),
                                ],
                              ),
                            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                            
                            const SizedBox(height: 32),
                            
                            // Mis Torneos
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Mis Torneos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                Text('${_misTorneos.length}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_misTorneos.isEmpty)
                              _buildEmptyState(theme, 'No has creado ningún torneo', Icons.emoji_events_outlined)
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _misTorneos.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (ctx, i) => _buildTorneoCard(_misTorneos[i], theme),
                              ).animate().fadeIn(delay: 600.ms),

                            const SizedBox(height: 32),

                            // Mis Equipos
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Mis Equipos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                Text('${_misEquipos.length}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_misEquipos.isEmpty)
                              _buildEmptyState(theme, 'No perteneces a ningún equipo', Icons.shield_outlined)
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _misEquipos.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (ctx, i) => _buildEquipoCard(_misEquipos[i], theme),
                              ).animate().fadeIn(delay: 700.ms),
                              
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTorneoCard(Torneo torneo, ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final updated = await Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => MiTorneoInfoScreen(torneo: torneo, onTorneoUpdated: _loadAll)),
        );
        if (updated == true) await _loadAll();
      },
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            if (torneo.categoriaId != null)
              CategoriaNetworkAvatar(categoriaId: torneo.categoriaId!, baseUrl: ApiConfig.baseUrl, size: 48)
            else
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.surface,
                child: Icon(Icons.emoji_events, color: theme.colorScheme.primary),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(torneo.nombre, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(_formatoFechasTorneo(torneo.fechaInicio, torneo.fechaFin), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipoCard(Equipo equipo, ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final updated = await Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => EquipoInfoScreen(equipo: equipo, onEquipoUpdated: _loadAll)),
        );
        if (updated == true) await _loadAll();
      },
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            EquipoNetworkAvatar(equipoId: equipo.idEquipo, baseUrl: ApiConfig.baseUrl, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(equipo.nombre, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (equipo.categoriaNombre != null && equipo.categoriaNombre!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                      child: Text(equipo.categoriaNombre!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
      label: Text(label),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _InfoTile({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      subtitle: Text(subtitle ?? '-', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
    );
  }
}
