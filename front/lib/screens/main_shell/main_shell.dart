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
import 'package:front/state/theme_state.dart';
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
        shadowColor: Theme.of(context).shadowColor.withOpacity(0.1),
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
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        title: const Text('Torneando'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeState.themeMode,
            builder: (context, themeMode, _) {
              final isDark = themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: 'Cambiar tema',
                onPressed: () {
                  ThemeState.toggleTheme();
                },
              );
            },
          ),
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
      floatingActionButton: SpeedDialFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex > 5 ? 0 : _currentIndex, // If creating tournament, keep selection
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Torneos',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categorías',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium),
            label: 'Destacados',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
        ],
      ),
    );
  }
}


