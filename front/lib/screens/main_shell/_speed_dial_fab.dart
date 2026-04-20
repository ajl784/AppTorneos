import 'package:flutter/material.dart';
import 'package:front/screens/crear_torneo/crear_torneo_wizard_screen.dart';
import 'package:front/screens/main_shell/crear_equipo_screen.dart';
import 'package:front/screens/main_shell/unirse_equipo_screen.dart';

class SpeedDialFab extends StatefulWidget {
  const SpeedDialFab({super.key});

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _controller.reverse();
      _removeOverlay();
    } else {
      _controller.forward();
      _showOverlay();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    final RenderBox fabRenderBox = context.findRenderObject() as RenderBox;
    final fabPosition = fabRenderBox.localToGlobal(Offset.zero);
    final fabSize = fabRenderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: fabPosition.dx + fabSize.width / 2 - 80,
        bottom: MediaQuery.of(context).size.height - fabPosition.dy + 10,
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SpeedDialOption(
                icon: Icons.group_add,
                label: 'Crear equipo',
                onTap: () {
                  _toggle();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CrearEquipoScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SpeedDialOption(
                icon: Icons.person_add_alt_1,
                label: 'Unirse a equipo',
                onTap: () {
                  _toggle();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UnirseEquipoScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SpeedDialOption(
                icon: Icons.emoji_events,
                label: 'Crear torneo',
                onTap: () {
                  _toggle();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CrearTorneoWizardScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: _isOpen ? 'Cerrar' : 'Crear',
      onPressed: _toggle,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white24, width: 1.5),
      ),
      child: AnimatedRotation(
        turns: _isOpen ? 0.125 : 0,
        duration: const Duration(milliseconds: 200),
        child: const Icon(Icons.add, size: 40),
      ),
    );
  }
}

class SpeedDialOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SpeedDialOption({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }
}
