import 'package:flutter/material.dart';

class GestionInvitacionesScreen extends StatelessWidget {
  const GestionInvitacionesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de invitaciones'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const Text(
              'Mis invitaciones a equipos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Equipo Placeholder FC'),
                subtitle: const Text('Te han invitado a unirte a este equipo.'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('Rechazar')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: () {}, child: const Text('Aceptar')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Mis invitaciones a arbitrar torneos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sports),
                title: const Text('Torneo Placeholder Cup'),
                subtitle: const Text('Te han invitado a arbitrar este torneo.'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('Rechazar')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: () {}, child: const Text('Aceptar')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
