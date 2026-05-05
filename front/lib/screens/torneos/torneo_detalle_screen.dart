import 'package:flutter/material.dart';

import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/features/torneos/domain/torneo.dart';
import 'package:front/features/torneos/domain/torneo_clasificacion.dart';
import 'package:front/features/torneos/domain/torneo_partidos.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/features/equipos/widgets/equipo_network_avatar.dart';

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

  static bool _isEliminacion(Torneo torneo) {
    final tipo = _norm(torneo.tipoTorneoNombre ?? '');
    return tipo.contains('eliminacion') || tipo.contains('eliminatoria');
  }

  static bool _isEliminacionPorSerie(Torneo torneo) {
    final tipo = _norm(torneo.tipoTorneoNombre ?? '');
    return tipo.contains('serie');
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

  Widget _buildBracket(int torneoId, {required bool agrupadoPorSerie}) {
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

        final partidosData = snapshot.data;
        final partidos = partidosData?.partidos ?? const <TorneoPartido>[];

        if (partidos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aún no hay partidos generados.'),
          );
        }

        // En eliminación (normal o por serie) solo mostramos la vista gráfica.
        // La vista por jornada se muestra únicamente en torneos tipo Liga.
        return _BracketSeriesView(
          partidos: partidos,
          agrupadoPorSerie: agrupadoPorSerie,
          normaPuntuacion: partidosData?.normaPuntuacion,
          tipoTorneoNombre: partidosData?.tipoTorneoNombre,
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
          final isEliminacion = _isEliminacion(torneo);
          final isSerie = _isEliminacionPorSerie(torneo);

          Widget content;
          if (!estadoVisible) {
            content = const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'La clasificación/bracket se mostrará cuando el torneo esté en curso o acabado.',
              ),
            );
          } else if (isLiga) {
            content = _LigaDetalleView(
              api: _api,
              torneoId: torneo.id,
              clasificacionBuilder: () => _buildClasificacion(torneo.id),
            );
          } else if (isEliminacion) {
            content = _buildBracket(torneo.id, agrupadoPorSerie: isSerie);
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

enum _LigaModo { clasificacion, jornada }

class _LigaDetalleView extends StatefulWidget {
  final TorneosApi api;
  final int torneoId;
  final Widget Function() clasificacionBuilder;

  const _LigaDetalleView({
    required this.api,
    required this.torneoId,
    required this.clasificacionBuilder,
  });

  @override
  State<_LigaDetalleView> createState() => _LigaDetalleViewState();
}

class _LigaDetalleViewState extends State<_LigaDetalleView> {
  _LigaModo _modo = _LigaModo.clasificacion;

  @override
  Widget build(BuildContext context) {
    final selection = <_LigaModo>{_modo};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: SegmentedButton<_LigaModo>(
            segments: const [
              ButtonSegment(
                value: _LigaModo.clasificacion,
                label: Text('Clasificación'),
              ),
              ButtonSegment(
                value: _LigaModo.jornada,
                label: Text('Jornada'),
              ),
            ],
            selected: selection,
            onSelectionChanged: (value) {
              if (value.isEmpty) return;
              setState(() => _modo = value.first);
            },
          ),
        ),
        Expanded(
          child: _modo == _LigaModo.clasificacion
              ? widget.clasificacionBuilder()
              : FutureBuilder<TorneoPartidos>(
                  future: widget.api.fetchPartidosTorneo(widget.torneoId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Error cargando partidos: ${snapshot.error}'),
                      );
                    }

                    final partidos = snapshot.data?.partidos ?? const <TorneoPartido>[];
                    if (partidos.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Aún no hay partidos generados.'),
                      );
                    }

                    return _JornadaNavigatorView(partidos: partidos);
                  },
                ),
        ),
      ],
    );
  }
}

class _BracketNode {
  final TorneoPartido display;
  final List<TorneoPartido> juegos;
  final int sortKey;

  const _BracketNode({
    required this.display,
    required this.juegos,
    required this.sortKey,
  });
}

class _BracketSeriesView extends StatelessWidget {
  final List<TorneoPartido> partidos;
  final bool agrupadoPorSerie;
  final String? normaPuntuacion;
  final String? tipoTorneoNombre;

  const _BracketSeriesView({
    required this.partidos,
    required this.agrupadoPorSerie,
    this.normaPuntuacion,
    this.tipoTorneoNombre,
  });

  /// Parse rondas_por_serie from norma_puntuacion
  static int _getRondasPorSerie(String? norma) {
    if (norma == null || norma.isEmpty) return 1;
    final parts = norma.split(';');
    for (final part in parts) {
      if (part.startsWith('rondas_por_serie=')) {
        final val = int.tryParse(part.substring('rondas_por_serie='.length));
        if (val != null && val > 0) return val;
      }
    }
    return 1;
  }

  /// Determina si es un torneo de eliminación por serie
  bool _isEliminacionPorSerie() {
    final tipo = tipoTorneoNombre ?? '';
    return tipo.toLowerCase().contains('serie');
  }

  static String _serieGroupKey(TorneoPartido p) {
    final ronda = p.ronda ?? 0;
    final ordenSerie = p.ordenSerie ?? 0;
    final next = p.idPartidoSiguiente ?? 0;

    final ids = p.equipos
        .map((e) => e.idParticipacionEquipo)
        .where((v) => v > 0)
        .toList(growable: false)
      ..sort();

    final participantsKey = ids.join(',');
    if (participantsKey.isNotEmpty) {
      return '$ronda|$ordenSerie|$next|$participantsKey';
    }

    final ord = p.ordenRonda;
    final ordBase = (ord == null) ? 0 : (ord >= 10 ? (ord ~/ 10) : ord);
    return '$ronda|$ordenSerie|$next|ord:$ordBase';
  }

  static int _baseOrden(TorneoPartido p) {
    final ord = p.ordenRonda;
    if (ord == null) return 0;
    return ord >= 10 ? (ord ~/ 10) : ord;
  }

  static String _normEstado(String? v) => (v ?? '').trim().toLowerCase();

  static String? _mergeEstado(List<TorneoPartido> juegos) {
    if (juegos.isEmpty) return null;
    final estados = juegos.map((g) => _normEstado(g.estado)).toSet();
    if (estados.contains('en_curso')) return 'en_curso';
    if (estados.isNotEmpty && estados.every((e) => e == 'acabado')) return 'acabado';
    if (estados.contains('planificado')) return 'planificado';
    return juegos.first.estado;
  }

  static TorneoPartido _aggregateSerie(List<TorneoPartido> juegos, {required int baseOrden}) {
    final sorted = [...juegos];
    sorted.sort((a, b) {
      final oa = a.ordenRonda ?? 0;
      final ob = b.ordenRonda ?? 0;
      if (oa != ob) return oa.compareTo(ob);
      final fa = a.fechaHora ?? '';
      final fb = b.fechaHora ?? '';
      final c = fa.compareTo(fb);
      if (c != 0) return c;
      return a.idPartido.compareTo(b.idPartido);
    });

    final first = sorted.first;
    final puntosByParticipacion = <int, TorneoPartidoEquipo>{};

    for (final g in sorted) {
      for (final e in g.equipos) {
        final prev = puntosByParticipacion[e.idParticipacionEquipo];
        if (prev == null) {
          puntosByParticipacion[e.idParticipacionEquipo] = TorneoPartidoEquipo(
            idParticipacionEquipo: e.idParticipacionEquipo,
            idEquipo: e.idEquipo,
            equipoNombre: e.equipoNombre,
            punto: e.punto,
          );
        } else {
          puntosByParticipacion[e.idParticipacionEquipo] = TorneoPartidoEquipo(
            idParticipacionEquipo: prev.idParticipacionEquipo,
            idEquipo: prev.idEquipo,
            equipoNombre: prev.equipoNombre,
            punto: prev.punto + e.punto,
          );
        }
      }
    }

    final equiposAgg = puntosByParticipacion.values.toList(growable: false);
    equiposAgg.sort((a, b) => a.idParticipacionEquipo.compareTo(b.idParticipacionEquipo));

    int? ganador;
    final estado = _mergeEstado(sorted);
    if (estado == 'acabado' && equiposAgg.length >= 2) {
      final max = equiposAgg.map((e) => e.punto).reduce((a, b) => a > b ? a : b);
      final maxOnes = equiposAgg.where((e) => e.punto == max).toList(growable: false);
      if (maxOnes.length == 1) {
        ganador = maxOnes.first.idParticipacionEquipo;
      }
    }

    return TorneoPartido(
      idPartido: first.idPartido,
      fechaHora: first.fechaHora,
      lugar: first.lugar,
      estado: estado,
      jornada: first.jornada,
      ronda: first.ronda,
      ordenRonda: baseOrden,
      idPartidoSiguiente: first.idPartidoSiguiente,
      ganadorIdParticipacionEquipo: ganador,
      equipos: equiposAgg,
    );
  }

  List<_BracketNode> _toNodes() {
    final inRounds = partidos.where((p) => p.ronda != null).toList(growable: false);
    final rondasPorSerie = _getRondasPorSerie(normaPuntuacion);
    final esEliminacionPorSerie = _isEliminacionPorSerie();
    
    if (!agrupadoPorSerie) {
      return inRounds
          .map(
            (p) => _BracketNode(
              display: p,
              juegos: [p],
              sortKey: p.ordenRonda ?? 0,
            ),
          )
          .toList(growable: false);
    }

    // Si es "Eliminación por serie", agrupar por (bloque, serie) para evitar mostrar nuevas columnas
    // dentro del mismo bloque de serie. Si no, agrupar por ronda normal.
    final groups = <String, List<TorneoPartido>>{};
    for (final p in inRounds) {
      final ronda = p.ronda ?? 0;
      
      String fullKey;
      if (esEliminacionPorSerie && rondasPorSerie > 1) {
        // Para eliminación por serie: agrupar SOLO por bloque y serie
        // Esto agrupa todas las subrondas (ronda 1 y 2) de la misma serie en UNA tarjeta
        final bloque = ((ronda - 1) ~/ rondasPorSerie);
        final serie = p.ordenSerie ?? 0;
        fullKey = '$bloque|$serie';
      } else {
        // Para otros torneos: solo agrupar por ronda
        fullKey = _serieGroupKey(p);
      }
      
      groups.putIfAbsent(fullKey, () => <TorneoPartido>[]).add(p);
    }

    final nodes = <_BracketNode>[];
    for (final entry in groups.entries) {
      final juegos = entry.value;
      final baseOrden = juegos.map(_baseOrden).fold<int>(0, (acc, v) => acc == 0 ? v : (v < acc ? v : acc));
      final display = juegos.length <= 1
          ? juegos.first
          : _aggregateSerie(juegos, baseOrden: baseOrden);

      nodes.add(
        _BracketNode(
          display: display,
          juegos: juegos,
          sortKey: baseOrden,
        ),
      );
    }

    nodes.sort((a, b) {
      final ra = a.display.ronda ?? 0;
      final rb = b.display.ronda ?? 0;
      
      if (esEliminacionPorSerie && rondasPorSerie > 1) {
        final blockeA = ((ra - 1) ~/ rondasPorSerie);
        final blockeB = ((rb - 1) ~/ rondasPorSerie);
        if (blockeA != blockeB) return blockeA.compareTo(blockeB);
        if (ra != rb) return ra.compareTo(rb);
        final serieA = a.display.ordenSerie ?? 0;
        final serieB = b.display.ordenSerie ?? 0;
        if (serieA != serieB) return serieA.compareTo(serieB);
      } else {
        if (ra != rb) return ra.compareTo(rb);
      }
      
      if (a.sortKey != b.sortKey) return a.sortKey.compareTo(b.sortKey);
      return a.display.idPartido.compareTo(b.display.idPartido);
    });

    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _toNodes();
    final rondasPorSerie = _getRondasPorSerie(normaPuntuacion);
    final esEliminacionPorSerie = _isEliminacionPorSerie();

    // Agrupar nodos por "bloque visual" (solo si es eliminación por serie con subrondas)
    final roundsMap = <int, List<_BracketNode>>{};
    for (final n in nodes) {
      final ronda = n.display.ronda;
      if (ronda == null) continue;
      
      // Si es "Eliminación por serie" con subrondas, agrupar por bloque; si no, agrupar por ronda
      final displayRound = (esEliminacionPorSerie && rondasPorSerie > 1) 
          ? ((ronda - 1) ~/ rondasPorSerie)  
          : ronda;
      
      roundsMap.putIfAbsent(displayRound, () => <_BracketNode>[]).add(n);
    }

    if (roundsMap.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Aún no hay rondas para mostrar.'),
      );
    }

    final orderedRounds = roundsMap.keys.toList(growable: false)..sort();
    for (final r in orderedRounds) {
      roundsMap[r]!.sort((a, b) {
        if (a.sortKey != b.sortKey) return a.sortKey.compareTo(b.sortKey);
        final oa = a.display.ordenRonda ?? 0;
        final ob = b.display.ordenRonda ?? 0;
        if (oa != ob) return oa.compareTo(ob);
        final serieA = a.display.ordenSerie ?? 0;
        final serieB = b.display.ordenSerie ?? 0;
        if (serieA != serieB) return serieA.compareTo(serieB);
        return a.display.idPartido.compareTo(b.display.idPartido);
      });
    }

    final cardWidth = 220.0;
    final cardHeight = 140.0;
    final roundGap = 72.0;
    final baseGap = 24.0;

    final firstRound = orderedRounds.first;
    final totalMatchesFirst = roundsMap[firstRound]!.length;
    final totalWidth = orderedRounds.length * cardWidth +
        (orderedRounds.length - 1) * roundGap +
        24;

    final initialStep = cardHeight + baseGap;
    final totalHeight =
        (totalMatchesFirst <= 1) ? cardHeight + 24 :
        ((totalMatchesFirst - 1) * initialStep + cardHeight + 24);

    final rectsByRound = <int, List<Rect>>{};
    final items = <Widget>[];

    for (var roundIndex = 0; roundIndex < orderedRounds.length; roundIndex++) {
      final roundNumber = orderedRounds[roundIndex];
      final matches = roundsMap[roundNumber]!;

      final step = initialStep * (1 << roundIndex);
      final topOffset = (step - cardHeight) / 2;
      final left = 12 + roundIndex * (cardWidth + roundGap);

      rectsByRound[roundNumber] = <Rect>[];

      for (var matchIndex = 0; matchIndex < matches.length; matchIndex++) {
        final node = matches[matchIndex];

        final top = 12 + topOffset + matchIndex * step;
        final rect = Rect.fromLTWH(left, top, cardWidth, cardHeight);
        rectsByRound[roundNumber]!.add(rect);

        items.add(
          Positioned(
            left: rect.left,
            top: rect.top,
            width: rect.width,
            height: rect.height,
            child: _MatchCard(
              partido: node.display,
              juegosSerie: node.juegos.length > 1 ? node.juegos : const <TorneoPartido>[],
              compact: true,
              bracketLabel: (esEliminacionPorSerie && rondasPorSerie > 1)
                  ? 'Bloque ${roundNumber + 1} · Serie ${node.display.ordenSerie ?? 0}'
                  : 'Ronda ${node.display.ronda ?? roundNumber}',
            ),
          ),
        );
      }

      items.add(
        Positioned(
          left: left,
          top: 0,
          width: cardWidth,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              (esEliminacionPorSerie && rondasPorSerie > 1)
                  ? 'Bloque ${roundNumber + 1}'
                  : 'Ronda $roundNumber',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
      );
    }

    final lineColor = Theme.of(context).colorScheme.outlineVariant;

    final stack = SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BracketLinesPainter(
                orderedRounds: orderedRounds,
                rectsByRound: rectsByRound,
                color: lineColor,
                hideConnectors: agrupadoPorSerie,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: stack,
        ),
      ),
    );
  }
}

class _JornadaNavigatorView extends StatefulWidget {
  final List<TorneoPartido> partidos;

  const _JornadaNavigatorView({required this.partidos});

  @override
  State<_JornadaNavigatorView> createState() => _JornadaNavigatorViewState();
}

class _JornadaNavigatorViewState extends State<_JornadaNavigatorView> {
  int _jornada = 1;

  static String _normEstado(String? v) => (v ?? '').trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final groups = <int, List<TorneoPartido>>{};
    for (final p in widget.partidos) {
      final j = p.jornada;
      if (j == null || j <= 0) continue;
      groups.putIfAbsent(j, () => <TorneoPartido>[]).add(p);
    }

    final maxJornada = groups.keys.isEmpty
        ? 1
        : groups.keys.fold<int>(1, (acc, v) => v > acc ? v : acc);

    final current = _jornada > maxJornada ? maxJornada : _jornada;
    if (current != _jornada) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _jornada = current);
      });
    }

    final partidosJornada = (groups[current] ?? const <TorneoPartido>[]).toList(growable: false)
      ..sort((a, b) {
        final fa = a.fechaHora ?? '';
        final fb = b.fechaHora ?? '';
        final c = fa.compareTo(fb);
        if (c != 0) return c;
        final oa = a.ordenRonda ?? 0;
        final ob = b.ordenRonda ?? 0;
        if (oa != ob) return oa.compareTo(ob);
        return a.idPartido.compareTo(b.idPartido);
      });

    Widget resultFor(TorneoPartido partido) {
      final equipos = partido.equipos;
      final a = equipos.isNotEmpty ? equipos[0] : null;
      final b = equipos.length > 1 ? equipos[1] : null;
      final estado = _normEstado(partido.estado);

      final showScore = a != null && b != null && (estado == 'en_curso' || estado == 'acabado');
      if (showScore) {
        return Text(
          '${a.punto} - ${b.punto}',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        );
      }

      final label = (estado.isEmpty || estado == 'planificado')
          ? 'Aún no ha empezado'
          : (estado == 'en_curso'
              ? 'En curso'
              : (estado == 'acabado' ? 'Acabado' : estado));

      return Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: current > 1 ? () => setState(() => _jornada = current - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Jornada anterior',
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Jornada $current / $maxJornada',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ),
              IconButton(
                onPressed: current < maxJornada ? () => setState(() => _jornada = current + 1) : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Jornada siguiente',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: partidosJornada.isEmpty
              ? const Center(child: Text('No hay partidos en esta jornada.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: partidosJornada.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = partidosJornada[index];
                    final equipos = p.equipos;
                    final a = equipos.isNotEmpty ? equipos[0] : null;
                    final b = equipos.length > 1 ? equipos[1] : null;

                    // Si el partido tiene más de dos equipos, mostrar un ExpansionTile
                    // con la fecha/hora y, al desplegar, el ranking de puntos.
                    if (p.equipos.length > 2) {
                      final equiposMulti = [...p.equipos];
                      equiposMulti.sort((x, y) => y.punto.compareTo(x.punto));
                      final allZero = equiposMulti.every((e) => e.punto == 0);

                      DateTime? dt = _MatchCard._tryParseDate(p.fechaHora)?.toLocal();
                      String subtitle;
                      if (dt == null) {
                        subtitle = p.lugar != null && p.lugar!.trim().isNotEmpty ? p.lugar!.trim() : '';
                      } else {
                        final hora = TimeOfDay.fromDateTime(dt).format(context);
                        subtitle = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} · $hora';
                      }

                      return Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          title: Text('Partido (${p.equipos.length} equipos)'),
                          subtitle: subtitle.isEmpty ? null : Text(subtitle),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ...equiposMulti.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final e = entry.value;
                                    final name = e.equipoNombre.trim().isEmpty ? 'TBD' : e.equipoNombre.trim();
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            child: Text('${idx + 1}', style: Theme.of(context).textTheme.bodySmall),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(name)),
                                          const SizedBox(width: 12),
                                          Text('${e.punto}', style: Theme.of(context).textTheme.bodyMedium),
                                        ],
                                      ),
                                    );
                                  }).toList(growable: false),
                                  if (allZero) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Aún no se tienen los resultados.',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Partidos 1v1 existentes (comportamiento previo)
                    return Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: _EquipoCell(
                                equipo: a,
                                alignLeft: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 72, maxWidth: 110),
                              child: Center(child: resultFor(p)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _EquipoCell(
                                equipo: b,
                                alignLeft: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EquipoCell extends StatelessWidget {
  final TorneoPartidoEquipo? equipo;
  final bool alignLeft;

  const _EquipoCell({
    required this.equipo,
    required this.alignLeft,
  });

  static String _displayName(TorneoPartidoEquipo? e) {
    final raw = (e?.equipoNombre ?? '').trim();
    return raw.isEmpty ? 'TBD' : raw;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _displayName(equipo);
    
    final avatar = equipo != null
        ? EquipoNetworkAvatar(
            equipoId: equipo!.idEquipo,
            baseUrl: ApiConfig.baseUrl,
            size: 36,
          )
        : Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.groups,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );

    final text = Flexible(
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium,
      ),
    );

    return Row(
      mainAxisAlignment: alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: alignLeft
          ? [
              avatar,
              const SizedBox(width: 8),
              text,
            ]
          : [
              text,
              const SizedBox(width: 8),
              avatar,
            ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final TorneoPartido partido;
  final List<TorneoPartido> juegosSerie;
  final bool compact;
  final String? bracketLabel;

  const _MatchCard({
    required this.partido,
    this.juegosSerie = const <TorneoPartido>[],
    this.compact = false,
    this.bracketLabel,
  });

  static double _meanPoints(List<TorneoPartidoEquipo> equipos) {
    if (equipos.isEmpty) return 0;
    final sum = equipos.fold<int>(0, (acc, e) => acc + e.punto);
    return sum / equipos.length;
  }

  static bool _isNearMean(int points, double mean) {
    final band = mean <= 0 ? 1.0 : (mean * 0.15).clamp(1.0, 999999.0);
    return (points - mean).abs() <= band;
  }

  static ({Color bg, Color fg, Color border}) _toneColors(ColorScheme colors, int points, double mean) {
    if (_isNearMean(points, mean)) {
      return (bg: colors.secondaryContainer, fg: colors.onSecondaryContainer, border: colors.secondary);
    }
    if (points > mean) {
      return (bg: colors.tertiaryContainer, fg: colors.onTertiaryContainer, border: colors.tertiary);
    }
    return (bg: colors.errorContainer, fg: colors.onErrorContainer, border: colors.error);
  }

  @override
  Widget build(BuildContext context) {
    final equipos = partido.equipos;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final vPad = compact ? 6.0 : 8.0;
    final rowGap = compact ? 4.0 : 6.0;
    final metaGap = compact ? 4.0 : 6.0;

    final localDate = _tryParseDate(partido.fechaHora)?.toLocal();
    final fechaLabel = localDate == null
      ? null
      : '${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}/${localDate.year.toString().padLeft(4, '0')}';
    final horaLabel = localDate == null ? null : TimeOfDay.fromDateTime(localDate).format(context);
    final lugarLabel = (partido.lugar == null || partido.lugar!.trim().isEmpty)
      ? null
      : partido.lugar!.trim();

    TorneoPartidoEquipo? winner;
    if (equipos.length >= 2) {
      final max = equipos.map((e) => e.punto).reduce((a, b) => a > b ? a : b);
      final maxOnes = equipos.where((e) => e.punto == max).toList(growable: false);
      if (maxOnes.length == 1 && (partido.estado ?? '').trim().toLowerCase() == 'acabado') {
        winner = maxOnes.first;
      }
    }

    final sortedEquipos = [...equipos]
      ..sort((a, b) {
        final c = b.punto.compareTo(a.punto);
        if (c != 0) return c;
        return a.equipoNombre.compareTo(b.equipoNombre);
      });
    final preview = sortedEquipos.take(4).toList(growable: false);

    // Card (cerrada): minimalista y sencilla.
    // El detalle bonito/estructurado vive en el diálogo al abrir.
    Widget rowForCard(TorneoPartidoEquipo e) {
      final name = (e.equipoNombre).trim().isEmpty ? 'TBD' : e.equipoNombre.trim();
      final score = e.punto;
      final isWinner = winner?.idEquipo == e.idEquipo;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$score',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isWinner ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final a = equipos.isNotEmpty ? equipos[0] : null;
    final b = equipos.length > 1 ? equipos[1] : null;

    final estado = (partido.estado == null || partido.estado!.trim().isEmpty)
        ? null
        : (partido.estado!.trim().toLowerCase() == 'acabado'
            ? 'Acabado'
            : (partido.estado!.trim().toLowerCase() == 'en_curso'
                ? 'En curso'
                : null));

    final vsTitle = _vsTitle(
      a?.equipoNombre,
      b?.equipoNombre,
    );

    final tituloDialog = equipos.length <= 2 ? vsTitle : 'Partido (${equipos.length} equipos)';

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (ctx) {
              final isSerie = juegosSerie.length > 1;

              List<TorneoPartidoEquipo> _sortedEquiposFor(List<TorneoPartidoEquipo> items) {
                final copy = [...items];
                copy.sort((a, b) {
                  final c = b.punto.compareTo(a.punto);
                  if (c != 0) return c;
                  return a.equipoNombre.compareTo(b.equipoNombre);
                });
                return copy;
              }

              Widget equiposTable(
                List<TorneoPartidoEquipo> items, {
                double? maxHeight,
              }) {
                final rows = _sortedEquiposFor(items);
                if (rows.isEmpty) return const Text('TBD');

                final mean = _meanPoints(rows);

                Widget row(TorneoPartidoEquipo e) {
                  final name = (e.equipoNombre).trim().isEmpty ? 'TBD' : e.equipoNombre.trim();
                  final tone = _toneColors(Theme.of(ctx).colorScheme, e.punto, mean);
                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: tone.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tone.border.withValues(alpha: 0.55)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                        color: tone.fg,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${e.punto}',
                                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                      color: tone.fg,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (maxHeight == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rows
                        .asMap()
                        .entries
                        .map((e) => Padding(
                              padding: EdgeInsets.only(bottom: e.key == rows.length - 1 ? 0 : 6),
                              child: row(e.value),
                            ))
                        .toList(growable: false),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: rows
                          .asMap()
                          .entries
                          .map((e) => Padding(
                                padding: EdgeInsets.only(bottom: e.key == rows.length - 1 ? 0 : 6),
                                child: row(e.value),
                              ))
                          .toList(growable: false),
                    ),
                  ),
                );
              }

              String juegoTitle(TorneoPartido g, int index) {
                final parts = <String>['Juego ${index + 1}'];
                final ord = g.ordenRonda;
                if (ord != null) parts.add('#$ord');
                final estado = (g.estado ?? '').trim();
                if (estado.isNotEmpty) parts.add(estado);
                return parts.join(' · ');
              }

              Widget serieList() {
                if (!isSerie) return const SizedBox.shrink();
                final sorted = [...juegosSerie];
                sorted.sort((a, b) {
                  final oa = a.ordenRonda ?? 0;
                  final ob = b.ordenRonda ?? 0;
                  if (oa != ob) return oa.compareTo(ob);
                  final fa = a.fechaHora ?? '';
                  final fb = b.fechaHora ?? '';
                  final c = fa.compareTo(fb);
                  if (c != 0) return c;
                  return a.idPartido.compareTo(b.idPartido);
                });

                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serie (${sorted.length} partidos)',
                        style: Theme.of(ctx).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...sorted.asMap().entries.map((e) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: e.key == sorted.length - 1 ? 0 : 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                juegoTitle(e.value, e.key),
                                style: Theme.of(ctx).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 6),
                              equiposTable(
                                e.value.equipos,
                                maxHeight: 160,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }

              return AlertDialog(
                title: Text(tituloDialog),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (lugarLabel != null) Text('Lugar: $lugarLabel'),
                        if (fechaLabel != null || horaLabel != null)
                          Text(
                            'Hora: ${[
                              if (fechaLabel != null) fechaLabel,
                              if (horaLabel != null) horaLabel,
                            ].join(' · ')}',
                          ),
                        if (estado != null) Text('Estado: $estado'),
                        if (partido.ronda != null)
                          Text(
                            'Ronda: ${partido.ronda}${partido.ordenRonda != null ? ' · #${partido.ordenRonda}' : ''}',
                          ),

                        if (equipos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Equipos',
                            style: Theme.of(ctx).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          equiposTable(
                            equipos,
                            maxHeight: 220,
                          ),
                        ],
                        serieList(),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            },
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: vPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                if (bracketLabel != null && bracketLabel!.isNotEmpty) ...[
                  Text(
                    bracketLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (sortedEquipos.isEmpty)
                  Text('TBD', style: theme.textTheme.bodyMedium)
                else
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Scrollbar(
                          child: ListView.separated(
                            primary: false,
                            padding: EdgeInsets.zero,
                            physics: const ClampingScrollPhysics(),
                            itemCount: sortedEquipos.length,
                            separatorBuilder: (_, __) => SizedBox(height: rowGap),
                            itemBuilder: (_, index) => rowForCard(sortedEquipos[index]),
                          ),
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                if (preview.isEmpty) ...[
                  Text('TBD', style: theme.textTheme.bodyMedium),
                ] else ...[
                  Column(
                    children: preview.asMap().entries.map((e) {
                      final w = rowForCard(e.value);
                      if (e.key == preview.length - 1) return w;
                      return Padding(
                        padding: EdgeInsets.only(bottom: rowGap),
                        child: w,
                      );
                    }).toList(growable: false),
                  ),
                  if (equipos.length > preview.length) ...[
                    const SizedBox(height: 2),
                    Text(
                      '+${equipos.length - preview.length} más',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ],
              if (juegosSerie.length > 1) ...[
                SizedBox(height: metaGap),
                Text(
                  'Serie · ${juegosSerie.length} partidos',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (estado != null) ...[
                SizedBox(height: metaGap),
                Text(
                  estado,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static DateTime? _tryParseDate(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return null;
    try {
      return DateTime.parse(v);
    } catch (_) {
      // Fallback: "YYYY-MM-DD HH:MM:SS" -> ISO-ish.
      try {
        return DateTime.parse(v.replaceFirst(' ', 'T'));
      } catch (_) {
        return null;
      }
    }
  }

  static String _vsTitle(String? a, String? b) {
    final left = (a ?? '').trim().isEmpty ? 'TBD' : a!.trim();
    final right = (b ?? '').trim().isEmpty ? 'TBD' : b!.trim();
    return '$left vs $right';
  }
}

class _BracketLinesPainter extends CustomPainter {
  final List<int> orderedRounds;
  final Map<int, List<Rect>> rectsByRound;
  final Color color;
  final bool hideConnectors;

  const _BracketLinesPainter({
    required this.orderedRounds,
    required this.rectsByRound,
    required this.color,
    this.hideConnectors = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hideConnectors) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < orderedRounds.length - 1; i++) {
      final r = orderedRounds[i];
      final next = orderedRounds[i + 1];
      final fromRects = rectsByRound[r] ?? const <Rect>[];
      final toRects = rectsByRound[next] ?? const <Rect>[];
      if (fromRects.isEmpty || toRects.isEmpty) continue;

      for (var matchIndex = 0; matchIndex < fromRects.length; matchIndex++) {
        final from = fromRects[matchIndex];
        final toIndex = matchIndex ~/ 2;
        if (toIndex < 0 || toIndex >= toRects.length) continue;
        final to = toRects[toIndex];

        final start = Offset(from.right, from.center.dy);
        final end = Offset(to.left, to.center.dy);
        final midX = start.dx + (end.dx - start.dx) / 2;

        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(midX, start.dy)
          ..lineTo(midX, end.dy)
          ..lineTo(end.dx, end.dy);

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BracketLinesPainter oldDelegate) {
    return oldDelegate.orderedRounds != orderedRounds ||
        oldDelegate.rectsByRound != rectsByRound ||
        oldDelegate.color != color ||
        oldDelegate.hideConnectors != hideConnectors;
  }
}
