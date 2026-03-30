import 'package:flutter/material.dart';

import 'auth_state.dart';
import 'login_register_screen.dart';
import 'perfil_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

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

  void _goToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
    );
  }

  void _openNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificaciones')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Torneos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),

        ],
      ),
      floatingActionButton: null,
    );
  }
}

class InicioTab extends StatelessWidget {
  const InicioTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Bienvenido a Torneando!'),
        ],
      ),
    );
  }
}

class TorneosTab extends StatelessWidget {
  const TorneosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Torneos'));
  }
}

class EstadisticasTab extends StatelessWidget {
  const EstadisticasTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Estadísticas'));
  }
}

class CalendarioTab extends StatelessWidget {
  const CalendarioTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Calendario'));
  }
}









