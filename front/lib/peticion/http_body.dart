import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/features/torneos/domain/torneo.dart';

class TorneosBody extends StatefulWidget {
  const TorneosBody({super.key});

  @override
  State<TorneosBody> createState() => _TorneosBodyState();
}

class _TorneosBodyState extends State<TorneosBody> {
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

  late final TorneosApi _api = TorneosApi(
    baseUrl: ApiConfig.baseUrl,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final colors = Theme.of(context).colorScheme;
            final cardBg = colors.primary;
            final onCard = colors.onPrimary;

            Widget featureBox(String text) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: onCard.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cardBg,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              );
            }

            final torneo = torneos[index];

            final inicio = _formatDate(torneo.fechaInicio);
            final fin = _formatDate(torneo.fechaFin);

            final features = <String>[];

            if (torneo.estado != null && torneo.estado!.trim().isNotEmpty) {
              features.add(_prettyEstado(torneo.estado!));
            }

            if (inicio != null || fin != null) {
              if (inicio != null && fin != null) {
                features.add('$inicio → $fin');
              } else if (inicio != null) {
                features.add(inicio);
              } else if (fin != null) {
                features.add(fin);
              }
            }

            if (torneo.categoriaNombre != null &&
                torneo.categoriaNombre!.trim().isNotEmpty) {
              features.add(torneo.categoriaNombre!);
            }

            if (torneo.tipoTorneoNombre != null &&
                torneo.tipoTorneoNombre!.trim().isNotEmpty) {
              features.add(torneo.tipoTorneoNombre!);
            }

            final hasDescripcion = torneo.descripcion != null &&
                torneo.descripcion!.trim().isNotEmpty;

            return Card(
              color: cardBg,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      torneo.nombre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: onCard,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    if (features.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: features.map(featureBox).toList(growable: false),
                      ),
                    if (hasDescripcion) ...[
                      if (features.isNotEmpty) const SizedBox(height: 10),
                      Divider(color: onCard.withValues(alpha: 0.25), height: 1),
                      const SizedBox(height: 10),
                      Text(
                        torneo.descripcion!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: onCard.withValues(alpha: 0.85),
                              height: 1.25,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
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