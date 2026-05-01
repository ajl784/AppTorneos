import 'package:front/screens/main_shell/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:front/state/auth_state.dart';
import 'package:front/state/jwt_storage.dart';
import 'package:front/features/notificaciones/data/notificaciones_api.dart';
import 'package:front/features/notificaciones/domain/notificacion.dart';
import 'package:front/peticion/api_config.dart';

class MisNotificacionesScreen extends StatefulWidget {
  const MisNotificacionesScreen({super.key});

  @override
  State<MisNotificacionesScreen> createState() => _MisNotificacionesScreenState();
}

class _MisNotificacionesScreenState extends State<MisNotificacionesScreen> {
  bool _loading = true;
  List<Notificacion> _notificaciones = [];
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateBadge();
  }

  @override
  void dispose() {
    _updateBadge();
    super.dispose();
  }

  /// Actualiza el badge global con la cantidad de notificaciones NO leídas
  void _updateBadge() async {
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 100));
    final jwtUser = await JwtStorage.getUser();
    if (jwtUser == null) {
      NotificationBadgeState.hasPending.value = false;
      return;
    }
    try {
      final idUsuario = int.parse(jwtUser['id_usuario'].toString());
      final notificacionesApi = NotificacionesApi(baseUrl: ApiConfig.baseUrl);
      final response = await notificacionesApi.getNotificaciones(leida: false);
      final noLeidas = response.data;
      NotificationBadgeState.hasPending.value = noLeidas.isNotEmpty;
    } catch (e) {
      NotificationBadgeState.hasPending.value = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNotificaciones();
  }

  Future<void> _fetchNotificaciones() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final jwtUser = await JwtStorage.getUser();
      if (jwtUser == null) throw Exception('No hay usuario logueado');
      final idUsuario = int.parse(jwtUser['id_usuario'].toString());
      final notificacionesApi = NotificacionesApi(baseUrl: ApiConfig.baseUrl);
      final response = await notificacionesApi.getNotificacionesByUsuario(idUsuario);
      setState(() {
        _notificaciones = response.data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar notificaciones: $e';
        _loading = false;
      });
    }
  }

  /// Maneja el tap en una notificación: marca como leída y decide navegación según tipo
  Future<void> _onNotificationTap(Notificacion notificacion) async {
    // Marcar como leída (si no lo estaba ya)
    if (!notificacion.leida) {
      try {
        final notificacionesApi = NotificacionesApi(baseUrl: ApiConfig.baseUrl);
        await notificacionesApi.marcarComoLeida(notificacion.idNotificacion);
        // Actualizar estado local para reflejar el cambio visual
        setState(() {
        final index = _notificaciones.indexWhere((n) => n.idNotificacion == notificacion.idNotificacion);
          if (index != -1) {
            // Creamos una nueva notificación con leida = true
            _notificaciones[index] = notificacion.copyWith(leida: true);
          }
        });
        // Actualizar badge global
        _updateBadge();
      } catch (e) {
        // Si falla el marcado, igual procedemos con la navegación
        debugPrint('Error al marcar como leída: $e');
      }
    }

    // Navegación según el tipo
    switch (notificacion.tipo) {
      case 'test_pantallainicio':
        // Ejemplo: lleva a la pantalla de inicio (MainShell)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainShell()),
          (route) => false,
        );
        break;

      // Aquí agregarás más casos según los tipos reales de tu backend
      // case 'solicitud_equipo':
      //   Navigator.pushNamed(context, '/gestion_torneos', arguments: notificacion.datos);
      //   break;

      default:
        // Por defecto, solo mostrar un snackbar o no hacer nada
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Notificación de tipo "${notificacion.tipo}" sin acción definida')),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: RefreshIndicator(
        onRefresh: _fetchNotificaciones,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _notificaciones.isEmpty
                    ? const Center(child: Text('No tienes notificaciones.'))
                    : ListView.builder(
                        itemCount: _notificaciones.length,
                        itemBuilder: (context, index) {
                          final notificacion = _notificaciones[index];
                          return ListTile(
                            leading: Icon(
                              notificacion.leida ? Icons.notifications_none : Icons.notifications_active,
                              color: notificacion.leida ? Colors.grey : Colors.blue,
                            ),
                            title: Text(
                              notificacion.titulo,
                              style: TextStyle(
                                fontWeight: notificacion.leida ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(notificacion.mensaje),
                            trailing: notificacion.leida ? null : const Icon(Icons.circle, size: 12, color: Colors.blue),
                            onTap: () => _onNotificationTap(notificacion),
                          );
                        },
                      ),
      ),
    );
  }
}