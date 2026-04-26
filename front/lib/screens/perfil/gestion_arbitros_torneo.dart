import 'package:flutter/material.dart';

class GestionArbitrosTorneoScreen extends StatelessWidget {
  final String torneoNombre;
  final int torneoId;

  const GestionArbitrosTorneoScreen({
    Key? key,
    required this.torneoNombre,
    required this.torneoId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController _arbitroController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de árbitros'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              torneoNombre,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            const Text(
              'Árbitros actuales:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Aquí se mostrarán los árbitros actuales...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Invitar árbitro',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _arbitroController,
                    decoration: const InputDecoration(
                      labelText: 'Email o nombre de usuario',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // En el futuro: lógica para invitar árbitro
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invitación enviada (simulado)')),
                    );
                    _arbitroController.clear();
                  },
                  child: const Text('Invitar árbitro'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
