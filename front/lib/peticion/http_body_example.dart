import 'package:flutter/material.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/features/torneos/domain/torneo.dart';

class TorneosScreenExample extends StatefulWidget {
  const TorneosScreenExample({super.key});

  @override
  State<TorneosScreenExample> createState() => _TorneosScreenExampleState();
}

class _TorneosScreenExampleState extends State<TorneosScreenExample> {
  late final TorneosApi _api = TorneosApi(
    baseUrl: 'http://10.0.2.2:3000',
  );

  late final Future<List<Torneo>> _future = _api.fetchTorneos();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torneos (ejemplo)'),
      ),
      body: FutureBuilder<List<Torneo>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final torneos = snapshot.data ?? const <Torneo>[];

          if (torneos.isEmpty) {
            return const Center(child: Text('Sin datos'));
          }

          return ListView.separated(
            itemCount: torneos.length,
            separatorBuilder: (_, separatorIndex) => Divider(
              key: ValueKey(separatorIndex),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final torneo = torneos[index];
              return ListTile(
                title: Text(torneo.nombre),
                subtitle: Text('ID: ${torneo.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
