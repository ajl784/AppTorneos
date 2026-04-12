import 'package:flutter/material.dart';

import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/features/torneos/domain/torneo.dart';
import 'package:front/features/torneos/domain/torneo_clasificacion.dart';
import 'package:front/features/torneos/domain/torneo_partidos.dart';
import 'package:front/peticion/api_config.dart';

class TorneoDetalleScreen extends StatefulWidget {
  final int torneoId;
  final String? torneoNombre;

  const TorneoDetalleScreen({
    super.key,
    required this.torneoId,
    this.torneoNombre,
  });

  @override
  State<TorneoDetalleScreen> createState() => _TorneoDetalleScreenState();
}

class _TorneoDetalleScreenState extends State<TorneoDetalleScreen> {
  late final TorneosApi _api = TorneosApi(baseUrl: ApiConfig.baseUrl);
  late final Future<Torneo> _futureTorneo = _api.fetchTorneoById(widget.torneoId);

  static String _norm(String value) {
    var v = value.trim().toLowerCase();
    v = v
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ñ', 'n');
    return v;
  }

  static bool _isEstadoVisible(Torneo torneo) {
    final estado = _norm(torneo.estado ?? '');
    return estado == 'en_curso' || estado == 'acabado';
  }

  static bool _isLiga(Torneo torneo) {
    final tipo = _norm(torneo.tipoTorneoNombre ?? '');
    return tipo == 'liga';
  }

  static bool _isEliminacionDirecta(Torneo torneo) {
    final tipo = _norm(torneo.tipoTorneoNombre ?? '');
    return tipo == 'eliminacion directa';
  }

  static String _prettyEstado(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'inscripcion_abierta':
      case 'inscripción_abierta':
        return 'Inscripción abierta';
      case 'inscripcion_terminada':
      case 'inscripción_terminada':
        return 'Inscripción terminada';
      case 'planificado':
        return 'Planificado';
      case 'en_curso':
      case 'en curso':
        return 'En curso';
      case 'acabado':
        return 'Acabado';
      case 'cancelado':
        return 'Cancelado';
      default:
        if (normalized.isEmpty) return '';
        return normalized.replaceFirst(
          normalized[0],
          normalized[0].toUpperCase(),
        );
    }
  }

  static String? _formatDate(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return trimmed;

    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} ${two(parsed.hour)}:${two(parsed.minute)}';
  }

  Widget _buildHeader(Torneo torneo) {
    final estado = (torneo.estado == null || torneo.estado!.trim().isEmpty)
        ? null
        : _prettyEstado(torneo.estado!);

    final tipo = (torneo.tipoTorneoNombre == null ||
            torneo.tipoTorneoNombre!.trim().isEmpty)
        ? null
        : torneo.tipoTorneoNombre!.trim();

    final categoria = (torneo.categoriaNombre == null ||
            torneo.categoriaNombre!.trim().isEmpty)
        ? null
        : torneo.categoriaNombre!.trim();

    final descripcion = (torneo.descripcion == null ||
            torneo.descripcion!.trim().isEmpty)
        ? null
        : torneo.descripcion!.trim();

    final inicio = _formatDate(torneo.fechaInicio);
    final fin = _formatDate(torneo.fechaFin);

    final features = <String>[];
    if (estado != null) features.add(estado);
    if (inicio != null || fin != null) {
      if (inicio != null && fin != null) {
        features.add('$inicio → $fin');
      } else if (inicio != null) {
        features.add(inicio);
      } else if (fin != null) {
        features.add(fin);
      }
    }
    if (categoria != null) features.add(categoria);
    if (tipo != null) features.add(tipo);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            torneo.nombre,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (features.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(growable: false),
            ),
          if (descripcion != null) ...[
            const SizedBox(height: 12),
            Text(
              descripcion,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClasificacion(int torneoId) {
    return FutureBuilder<TorneoClasificacion>(
      future: _api.fetchClasificacionTorneo(torneoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error cargando clasificación: ${snapshot.error}'),
          );
        }

        final data = snapshot.data;
        final items = data?.clasificacion ?? const <TorneoClasificacionItem>[];

        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aún no hay datos de clasificación.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final it = items[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text('${it.posicion}'),
              ),
              title: Text(it.equipoNombre),
              subtitle: Text('ELO: ${it.elo}'),
              trailing: Text(
                '${it.puntos} pts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBracket(int torneoId) {
    return FutureBuilder<TorneoPartidos>(
      future: _api.fetchPartidosTorneo(torneoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error cargando bracket: ${snapshot.error}'),
          );
        }

        final partidos = snapshot.data?.partidos ?? const <TorneoPartido>[];

        if (partidos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aún no hay partidos generados.'),
          );
        }

        final Map<int?, List<TorneoPartido>> porRonda = {};
        for (final p in partidos) {
          porRonda.putIfAbsent(p.ronda, () => <TorneoPartido>[]).add(p);
        }

        final rondasOrdenadas = porRonda.keys.toList(growable: false)
          ..sort((a, b) {
            if (a == null && b == null) return 0;
            if (a == null) return 1;
            if (b == null) return -1;
            return a.compareTo(b);
          });

        final tiles = <Widget>[];
        for (final ronda in rondasOrdenadas) {
          final items = porRonda[ronda] ?? const <TorneoPartido>[];
          final title = ronda == null ? 'Partidos' : 'Ronda $ronda';

          tiles.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );

          tiles.addAll(
            items.map((p) {
              final fecha = _formatDate(p.fechaHora);
              final estado = (p.estado == null || p.estado!.trim().isEmpty)
                  ? null
                  : _prettyEstado(p.estado!);

              final equiposText = p.equipos.isEmpty
                  ? 'Sin participantes'
                  : p.equipos
                      .map((e) => '${e.equipoNombre} (${e.punto})')
                      .join('  ·  ');

              final subtitleParts = <String>[];
              if (fecha != null) subtitleParts.add(fecha);
              if (estado != null) subtitleParts.add(estado);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(equiposText),
                  subtitle: subtitleParts.isEmpty
                      ? null
                      : Text(subtitleParts.join('  ·  ')),
                ),
              );
            }),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 12),
          children: tiles,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.torneoNombre ?? 'Detalle del torneo'),
      ),
      body: FutureBuilder<Torneo>(
        future: _futureTorneo,
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

          final torneo = snapshot.data;
          if (torneo == null) {
            return const Center(child: Text('Torneo no encontrado'));
          }

          final estadoVisible = _isEstadoVisible(torneo);
          final isLiga = _isLiga(torneo);
          final isEliminacionDirecta = _isEliminacionDirecta(torneo);

          Widget content;
          if (!estadoVisible) {
            content = const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'La clasificación/bracket se mostrará cuando el torneo esté en curso o acabado.',
              ),
            );
          } else if (isLiga) {
            content = _buildClasificacion(torneo.id);
          } else if (isEliminacionDirecta) {
            content = _buildBracket(torneo.id);
          } else {
            content = const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Este tipo de torneo aún no tiene vista de detalle implementada.',
              ),
            );
          }

          return Column(
            children: [
              _buildHeader(torneo),
              const Divider(height: 1),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}
