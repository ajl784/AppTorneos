import 'package:flutter/material.dart';

class BusquedaScreen extends StatelessWidget {
  const BusquedaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda'),
      ),
      body: const Center(
        child: Text('Búsqueda'),
      ),
    );
  }
}
