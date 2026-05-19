import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:front/peticion/api_config.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:flutter/material.dart';

import 'package:front/screens/login_register/login_register_screen.dart';
import 'package:front/screens/main_shell/tabs/calendario_tab.dart';
import 'package:front/screens/main_shell/tabs/categorias_tab.dart';
import 'package:front/screens/main_shell/tabs/crear_torneo_tab.dart';
import 'package:front/screens/main_shell/tabs/destacados_tab.dart';
import 'package:front/screens/main_shell/tabs/estadisticas_tab.dart';
import 'package:front/screens/main_shell/tabs/inicio_tab.dart';
import 'package:front/screens/main_shell/tabs/torneos_tab.dart';
import 'package:front/screens/main_shell/_speed_dial_fab.dart';
import 'package:front/screens/perfil/perfil_screen.dart';
import 'package:front/state/auth_state.dart';
import 'package:front/state/jwt_storage.dart';
import 'package:front/features/usuarios/data/usuarios_api.dart';
import 'package:front/screens/main_shell/mis_notificaciones.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class NotificationBadgeState {
  static final ValueNotifier<bool> hasPending = ValueNotifier(false);
}


class _MainShellState extends State<MainShell> {
    // Control para el badge de notificaciones
    late final ValueNotifier<bool> _hasPendingNotifications;
    StreamSubscription? _notificacionesSub;

  int _currentIndex = 0;
  ImageProvider? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    AuthState.isLoggedIn.addListener(_loadProfileImage);

    _hasPendingNotifications = NotificationBadgeState.hasPending;
    _checkPendingNotifications();
  }

  @override
  void dispose() {
    AuthState.isLoggedIn.removeListener(_loadProfileImage);
    _notificacionesSub?.cancel();
    super.dispose();
  }
  Future<void> _checkPendingNotifications() async {
    try {
      final jwtUser = await JwtStorage.getUser();
      if (jwtUser == null) {
        _hasPendingNotifications.value = false;
        return;
      }
      final int idUsuario = int.parse(jwtUser['id_usuario'].toString());
      final torneosApi = TorneosApi(baseUrl: ApiConfig.baseUrl);
      final response = await torneosApi.listTorneos(organizadorId: idUsuario);
      final torneos = response.data;
      bool found = false;
      for (final torneo in torneos) {
        final idTorneo = torneo.id;
        final url = ApiConfig.baseUrl.replaceAll('/api/v1', '') + '/api/v1/torneos/$idTorneo/solicitudes?estado=pendiente';
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          if (data['ok'] == true && data['meta'] != null && data['meta']['count'] > 0) {
            found = true;
            break;
          }
        }
      }
      _hasPendingNotifications.value = found;
    } catch (_) {
      _hasPendingNotifications.value = false;
    }
  }

  Future<void> _loadProfileImage() async {
    if (!AuthState.isLoggedIn.value) {
      setState(() {
        _profileImage = null;
      });
      return;
    }
    try {
      // Obtener el usuario logueado y su foto de perfil
      final jwtUser = await JwtStorage.getUser();
      if (jwtUser == null) throw Exception('No hay usuario logueado');
      final int idUsuario = int.parse(jwtUser['id_usuario'].toString());
      final usuariosApi = UsuariosApi(baseUrl: ApiConfig.baseUrl);
      final userResp = await usuariosApi.getUsuarioById(idUsuario);
      ImageProvider? profileImage;
      if (userResp.fotoperfil != null) {
        final url = ApiConfig.baseUrl.replaceAll('/api/v1', '') + '/api/v1/usuarios/$idUsuario/profile-pic';
        profileImage = NetworkImage(url);
      } else {
        profileImage = null;
      }
      setState(() {
        _profileImage = profileImage;
      });
    } catch (_) {
      setState(() {
        _profileImage = null;
      });
    }
  }

  void _goToProfile() async {
    if (AuthState.isLoggedIn.value) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const PerfilScreen()),
      );
      // Al volver del perfil, recarga la imagen
      _loadProfileImage();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
    );
  }

  void _openNotifications() async {
    // Navega y espera el resultado
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MisNotificacionesScreen(),
      ),
    );
    // Al volver, vuelve a comprobar
    _checkPendingNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color selectedColor = colors.primary;
    final Color unselectedColor = colors.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: ValueListenableBuilder<bool>(
          valueListenable: _hasPendingNotifications,
          builder: (context, hasPending, child) {
            return Stack(
              children: [
                IconButton(
                  tooltip: 'Notificaciones',
                  icon: const Icon(Icons.notifications),
                  onPressed: _openNotifications,
                ),
                if (hasPending)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        title: const Text('Torneando'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _goToProfile,
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                backgroundImage: _profileImage,
                child: _profileImage == null ? const Icon(Icons.person) : null,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          InicioTab(
            onJoinTournament: () => setState(() => _currentIndex = 1),
            onCreateTournament: () => setState(() => _currentIndex = 6),
            onBrowseCategories: () => setState(() => _currentIndex = 2),
          ),
          const TorneosTab(),
          const CategoriasTab(),
          const DestacadosTab(),
          const EstadisticasTab(),
          const CalendarioTab(),
          const CrearTorneoTab(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SpeedDialFab(),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                label: 'Inicio',
                icon: Icons.home,
                isSelected: _currentIndex == 0,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                label: 'Torneos',
                icon: Icons.emoji_events,
                isSelected: _currentIndex == 1,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavItem(
                label: 'Categorías',
                icon: Icons.category,
                isSelected: _currentIndex == 2,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              const SizedBox(width: 64),
              _NavItem(
                label: 'Destacados',
                icon: Icons.workspace_premium,
                isSelected: _currentIndex == 3,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: () => setState(() => _currentIndex = 3),
              ),
              _NavItem(
                label: 'Estadísticas',
                icon: Icons.bar_chart,
                isSelected: _currentIndex == 4,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: () => setState(() => _currentIndex = 4),
              ),
              _NavItem(
                label: 'Calendario',
                icon: Icons.calendar_month,
                isSelected: _currentIndex == 5,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: () => setState(() => _currentIndex = 5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected ? selectedColor : unselectedColor;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
