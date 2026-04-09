import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/features/torneos/domain/torneo.dart';

class TorneosBody extends StatefulWidget {
  const TorneosBody({super.key});

  @override
  State<TorneosBody> createState() => _TorneosBodyState();
}

class _TorneosBodyState extends State<TorneosBody> {
  static String _defaultApiBaseUrl() {
    if (kIsWeb) {
      final host = (Uri.base.host.isNotEmpty) ? Uri.base.host : 'localhost';
      return 'http://$host:3000/api/v1';
    }

    return 'http://10.0.2.2:3000/api/v1';
  }

  late final TorneosApi _api = TorneosApi(
    baseUrl: _defaultApiBaseUrl(),
  );

  late final Future<List<Torneo>> _future = _api.fetchTorneos();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Torneo>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snapshot.error}'),
            ),
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

            final parts = <String>[];
            if (torneo.estado != null && torneo.estado!.trim().isNotEmpty) {
              parts.add(torneo.estado!);
            }

            final inicio = torneo.fechaInicio;
            final fin = torneo.fechaFin;
            if (inicio != null && inicio.trim().isNotEmpty) {
              if (fin != null && fin.trim().isNotEmpty) {
                parts.add('$inicio → $fin');
              } else {
                parts.add('Inicio: $inicio');
              }
            } else if (fin != null && fin.trim().isNotEmpty) {
              parts.add('Fin: $fin');
            }

            if (torneo.categoriaNombre != null &&
                torneo.categoriaNombre!.trim().isNotEmpty) {
              parts.add('Categoría: ${torneo.categoriaNombre}');
            }

            if (torneo.tipoTorneoNombre != null &&
                torneo.tipoTorneoNombre!.trim().isNotEmpty) {
              parts.add('Tipo: ${torneo.tipoTorneoNombre}');
            }

            return ListTile(
              title: Text(torneo.nombre),
              subtitle: parts.isEmpty
                  ? (torneo.descripcion != null &&
                          torneo.descripcion!.trim().isNotEmpty
                      ? Text(torneo.descripcion!)
                      : null)
                  : Text(parts.join(' · ')),
            );
          },
        );
      },
    );
  }
}

class TorneosScreenExample extends StatefulWidget {
  const TorneosScreenExample({super.key});

  @override
  State<TorneosScreenExample> createState() => _TorneosScreenExampleState();
}

class _TorneosScreenExampleState extends State<TorneosScreenExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torneos (ejemplo)'),
      ),
      body: const TorneosBody(),
    );
  }
}
