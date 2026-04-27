import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:front/api/api_exception.dart';
import 'package:front/features/equipos/data/equipos_api.dart';
import 'package:front/features/equipos/domain/equipo.dart';
import 'package:front/features/estadisticas/domain/estadisticas_models.dart';
import 'package:front/features/participaciones/data/participaciones_api.dart';
import 'package:front/features/participaciones/domain/participacion.dart';
import 'package:front/peticion/api_config.dart';

class DestacadosTab extends StatefulWidget {
  const DestacadosTab({super.key});

  @override
  State<DestacadosTab> createState() => _DestacadosTabState();
}

class _DestacadosTabState extends State<DestacadosTab> {
  late final EquiposApi _equiposApi = EquiposApi(baseUrl: ApiConfig.baseUrl);
  late Future<List<_CategoriaDestacada>> _futureCategorias;

  @override
  void initState() {
    super.initState();
    _futureCategorias = _loadCategoriasDestacadas();
  }

  Future<List<Equipo>> _loadAllEquipos() async {
    const pageSize = 200;
    final equipos = <Equipo>[];
    var offset = 0;

    while (true) {
      final response = await _equiposApi.listEquipos(limit: pageSize, offset: offset);
      equipos.addAll(response.data);
      if (response.data.length < pageSize) {
        break;
      }
      offset += pageSize;
    }

    return equipos;
  }

  Future<List<_CategoriaDestacada>> _loadCategoriasDestacadas() async {
    final equipos = await _loadAllEquipos();
    final grouped = <int, List<Equipo>>{};
    final categoryNames = <int, String>{};

    for (final equipo in equipos) {
      final idCategoria = equipo.idCategoria;
      if (idCategoria == null) continue;
      grouped.putIfAbsent(idCategoria, () => <Equipo>[]).add(equipo);
      if (equipo.categoriaNombre != null && equipo.categoriaNombre!.trim().isNotEmpty) {
        categoryNames[idCategoria] = equipo.categoriaNombre!.trim();
      }
    }

    final items = grouped.entries.map((entry) {
      final sorted = entry.value.toList(growable: false)
        ..sort((a, b) {
          final eloA = a.elo ?? 0;
          final eloB = b.elo ?? 0;
          final cmp = eloB.compareTo(eloA);
          if (cmp != 0) return cmp;
          return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
        });

      final topEquipo = sorted.first;
      final categoryName = categoryNames[entry.key] ?? 'Categoría ${entry.key}';
      return _CategoriaDestacada(
        nombreCategoria: categoryName,
        equipo: topEquipo,
        totalEquipos: entry.value.length,
      );
    }).toList(growable: false);

    items.sort((a, b) {
      final eloCmp = (b.equipo.elo ?? 0).compareTo(a.equipo.elo ?? 0);
      if (eloCmp != 0) return eloCmp;
      return a.nombreCategoria.toLowerCase().compareTo(b.nombreCategoria.toLowerCase());
    });

    return items;
  }

  Future<void> _refresh() async {
    setState(() {
      _futureCategorias = _loadCategoriasDestacadas();
    });
    await _futureCategorias;
  }

  Future<void> _openEquipoDetail(_CategoriaDestacada destacado) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EquipoDestacadoSheet(
        equipo: destacado.equipo,
        categoriaNombre: destacado.nombreCategoria,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
          ],
        ),
      ),
      child: FutureBuilder<List<_CategoriaDestacada>>(
        future: _futureCategorias,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No se pudieron cargar los equipos destacados.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final categorias = snapshot.data ?? const <_CategoriaDestacada>[];

          if (categorias.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _HeaderCard(
                    categoriaCount: 0,
                    equipoCount: 0,
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text('Aún no hay equipos con categoría asignada.'),
                    ),
                  ),
                ],
              ),
            );
          }

          final totalEquipos = categorias.fold<int>(0, (sum, item) => sum + item.totalEquipos);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _HeaderCard(
                  categoriaCount: categorias.length,
                  equipoCount: totalEquipos,
                ),
                const SizedBox(height: 20),
                Text(
                  'Hall of Fame',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Solo entra el #1 de cada categoría. Si quieres que tu equipo aparezca aquí, toca una tarjeta y revisa qué nivel hay que alcanzar.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...categorias.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _CategoryShowcaseCard(
                      categoria: item,
                      onTap: () => _openEquipoDetail(item),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.categoriaCount, required this.equipoCount});

  final int categoriaCount;
  final int equipoCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF38BDF8),
            const Color(0xFF7DD3FC),
            const Color(0xFFBAE6FD),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C4A6E).withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -18,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.16),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -24,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Zona de élite',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hall of Fame',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Solo los líderes absolutos por categoría',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatChip(label: 'Categorías en disputa', value: categoriaCount.toString()),
                    _StatChip(label: 'Equipos analizados', value: equipoCount.toString()),
                    const _StatChip(label: 'Filtro', value: 'Solo #1'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryShowcaseCard extends StatelessWidget {
  const _CategoryShowcaseCard({required this.categoria, required this.onTap});

  final _CategoriaDestacada categoria;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final team = categoria.equipo;
    final theme = Theme.of(context);
    final elo = team.elo ?? 0;
    final crownState = elo >= 1900
        ? 'Defiende el trono'
        : elo >= 1800
            ? 'A un paso de la leyenda'
            : 'En ascenso a la cima';
    final rarity = elo >= 1900
        ? 'Legendario'
        : elo >= 1800
            ? 'Épico'
            : 'Competitivo';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8FCFF), Color(0xFFE8F5FF)],
            ),
            border: Border.all(color: const Color(0xFF7DD3FC).withOpacity(0.28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TagPill(
                      icon: Icons.verified,
                      label: crownState,
                      background: const Color(0xFFDBEAFE),
                      foreground: const Color(0xFF1D4ED8),
                    ),
                    _TagPill(
                      icon: Icons.shield_moon,
                      label: rarity,
                      background: const Color(0xFFE0F2FE),
                      foreground: const Color(0xFF0369A1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF7DD3FC),
                            theme.colorScheme.primary,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.workspace_premium, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoria.nombreCategoria,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF0EA5E9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            team.nombre,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            categoria.totalEquipos == 1
                                ? '1 equipo registrado en esta categoría'
                                : '${categoria.totalEquipos} equipos compiten aquí',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _RankBadge(elo: elo),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _EloBlock(elo: elo),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.78),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meta para entrar aquí',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: const Color(0xFF0EA5E9),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Supera este ELO y gana visibilidad en la app',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Toca para ver torneos y evolución del líder',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF0C4A6E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFF0284C7)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.elo});

  final int elo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFBAE6FD).withOpacity(0.24),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '#1',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF0284C7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$elo ELO',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF0284C7),
            ),
          ),
        ],
      ),
    );
  }
}

class _EloBlock extends StatelessWidget {
  const _EloBlock({required this.elo});

  final int elo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ELO',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            elo.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipoDestacadoSheet extends StatefulWidget {
  const _EquipoDestacadoSheet({
    required this.equipo,
    required this.categoriaNombre,
  });

  final Equipo equipo;
  final String categoriaNombre;

  @override
  State<_EquipoDestacadoSheet> createState() => _EquipoDestacadoSheetState();
}

class _EquipoDestacadoSheetState extends State<_EquipoDestacadoSheet> {
  late final EquiposApi _equiposApi = EquiposApi(baseUrl: ApiConfig.baseUrl);
  late final Future<_EquipoDetalleData> _futureDetalle;

  @override
  void initState() {
    super.initState();
    _futureDetalle = _loadDetalle();
  }

  Future<List<Participacion>> _loadParticipaciones(int idEquipo) async {
    final participacionesApi = ParticipacionesApi(baseUrl: ApiConfig.baseUrl);
    const pageSize = 100;
    final items = <Participacion>[];
    var offset = 0;

    while (true) {
      final response = await participacionesApi.listParticipaciones(
        limit: pageSize,
        offset: offset,
        equipoId: idEquipo,
      );
      items.addAll(response.data);
      if (response.data.length < pageSize) {
        break;
      }
      offset += pageSize;
    }

    items.sort((a, b) {
      final dateA = DateTime.tryParse(a.fecha ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(b.fecha ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    return items;
  }

  Future<_EquipoDetalleData> _loadDetalle() async {
    EloHistorialResponse historial;
    try {
      historial = await _equiposApi.getEloHistorialEquipo(widget.equipo.idEquipo);
    } on ApiException catch (e) {
      // Fallback temporal cuando el backend todavía no expone /equipos/:id/elo-historial.
      if (e.statusCode == 404) {
        historial = EloHistorialResponse(
          equipo: EquipoElo(
            idEquipo: widget.equipo.idEquipo,
            nombre: widget.equipo.nombre,
            eloActual: widget.equipo.elo ?? 0,
          ),
          historial: const [],
        );
      } else {
        rethrow;
      }
    }

    final participaciones = await _loadParticipaciones(widget.equipo.idEquipo);

    return _EquipoDetalleData(
      historial: historial,
      participaciones: participaciones,
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Sin fecha';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year}';
  }

  List<FlSpot> _spotsFromHistorial(List<EloPoint> points, int fallbackElo) {
    if (points.isEmpty) {
      return [
        FlSpot(0, fallbackElo.toDouble()),
        FlSpot(1, fallbackElo.toDouble()),
      ];
    }

    return List.generate(
      points.length,
      (index) => FlSpot(index.toDouble(), points[index].eloNuevo.toDouble()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eloActual = widget.equipo.elo ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: FutureBuilder<_EquipoDetalleData>(
            future: _futureDetalle,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No se pudo cargar el detalle del equipo.',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(snapshot.error.toString(), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }

              final detalle = snapshot.data!;
              final historial = detalle.historial.historial;
              final participaciones = detalle.participaciones;
              final spots = _spotsFromHistorial(historial, eloActual);
              final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
              final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.categoriaNombre,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.equipo.nombre,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _SheetChip(label: 'ELO actual', value: eloActual.toString()),
                            _SheetChip(label: 'Categoría', value: widget.equipo.categoriaNombre ?? widget.categoriaNombre),
                            _SheetChip(label: 'Torneos', value: participaciones.length.toString()),
                          ],
                        ),
                        if ((widget.equipo.descripcion ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            widget.equipo.descripcion!.trim(),
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Evolución del ELO',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (historial.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('Todavía no hay historial de ELO para este equipo.'),
                          )
                        else
                          SizedBox(
                            height: 220,
                            child: LineChart(
                              LineChartData(
                                minY: minY - 40,
                                maxY: maxY + 40,
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipRoundedRadius: 10,
                                    getTooltipColor: (_) => theme.colorScheme.surface,
                                    fitInsideHorizontally: true,
                                    fitInsideVertically: true,
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        final value = spot.y.round();
                                        return LineTooltipItem(
                                          '$value ELO',
                                          theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurface,
                                                fontWeight: FontWeight.w700,
                                              ) ??
                                              TextStyle(
                                                color: theme.colorScheme.onSurface,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        );
                                      }).toList(growable: false);
                                    },
                                  ),
                                ),
                                titlesData: const FlTitlesData(
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    barWidth: 4,
                                    color: theme.colorScheme.primary,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: theme.colorScheme.primary.withOpacity(0.14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        if (historial.isNotEmpty)
                          Text(
                            'Primer registro: ${historial.first.eloNuevo} | Último registro: ${historial.last.eloNuevo}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Torneos en los que ha participado',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (participaciones.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Este equipo todavía no tiene participaciones registradas.'),
                    )
                  else
                    ...participaciones.map(
                      (participacion) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    participacion.torneoNombre ?? 'Torneo',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _StatusPill(label: _prettyEstado(participacion.estado)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MiniInfo(label: 'Fecha', value: _formatDate(participacion.fecha)),
                                _MiniInfo(label: 'Puntuación', value: (participacion.puntuacion ?? 0).toString()),
                                if ((participacion.equipoNombre ?? '').isNotEmpty)
                                  _MiniInfo(label: 'Equipo', value: participacion.equipoNombre ?? ''),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _prettyEstado(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'pendiente':
        return 'Pendiente';
      case 'jugando':
        return 'Jugando';
      case 'suspendido':
        return 'Suspendido';
      case 'eliminado':
        return 'Eliminado';
      case 'aceptada':
        return 'Aceptada';
      case 'rechazada':
        return 'Rechazada';
      default:
        if (normalized.isEmpty) return 'Sin estado';
        return normalized;
    }
  }
}

class _SheetChip extends StatelessWidget {
  const _SheetChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFBAE6FD).withOpacity(0.24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0284C7),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _CategoriaDestacada {
  final String nombreCategoria;
  final Equipo equipo;
  final int totalEquipos;

  const _CategoriaDestacada({
    required this.nombreCategoria,
    required this.equipo,
    required this.totalEquipos,
  });
}

class _EquipoDetalleData {
  final EloHistorialResponse historial;
  final List<Participacion> participaciones;

  const _EquipoDetalleData({
    required this.historial,
    required this.participaciones,
  });
}
