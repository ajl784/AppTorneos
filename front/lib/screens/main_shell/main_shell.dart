import 'package:flutter/material.dart';

import 'package:front/screens/login_register/login_register_screen.dart';
import 'package:front/screens/main_shell/tabs/calendario_tab.dart';
import 'package:front/screens/main_shell/tabs/crear_torneo_tab.dart';
import 'package:front/screens/main_shell/tabs/estadisticas_tab.dart';
import 'package:front/screens/main_shell/tabs/inicio_tab.dart';
import 'package:front/screens/main_shell/tabs/torneos_tab.dart';
import 'package:front/screens/perfil/perfil_screen.dart';
import 'package:front/state/auth_state.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const int _crearTorneoTabIndex = 4;

  void _goToProfile() {
    if (AuthState.isLoggedIn.value) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const PerfilScreen()),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
    );
  }

  void _openNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificaciones')),
    );
  }

  void _goToCrearTorneoTab() {
    setState(() => _currentIndex = _crearTorneoTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color selectedColor = colors.primary;
    final Color unselectedColor = colors.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          tooltip: 'Notificaciones',
          icon: const Icon(Icons.notifications),
          onPressed: _openNotifications,
        ),
        title: const Text('Torneando'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _goToProfile,
              customBorder: const CircleBorder(),
              child: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const InicioTab(),
          const TorneosTab(),
          const EstadisticasTab(),
          const CalendarioTab(),
          const CrearTorneoTab(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          tooltip: 'Crear torneo',
          onPressed: _goToCrearTorneoTab,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white24, width: 1.5),
          ),
          child: const Icon(Icons.add, size: 40),
        ),
      ),
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
              const SizedBox(width: 64),
              _NavItem(
                label: 'Estadísticas',
                icon: Icons.bar_chart,
                isSelected: _currentIndex == 2,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavItem(
                label: 'Calendario',
                icon: Icons.calendar_month,
                isSelected: _currentIndex == 3,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: () => setState(() => _currentIndex = 3),
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
