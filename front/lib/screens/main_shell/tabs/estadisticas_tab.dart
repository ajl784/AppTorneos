import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';

import 'package:front/features/categorias/widgets/categoria_network_avatar.dart';
import 'package:front/features/estadisticas/data/estadisticas_api.dart';
import 'package:front/features/estadisticas/domain/estadisticas_models.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/state/auth_state.dart';
import 'package:front/state/jwt_storage.dart';

class EstadisticasTab extends StatefulWidget {
  const EstadisticasTab({super.key});

  @override
  State<EstadisticasTab> createState() => _EstadisticasTabState();
}

class _EstadisticasTabState extends State<EstadisticasTab> {
  final EstadisticasApi _api = EstadisticasApi(baseUrl: ApiConfig.baseUrl);

  late final VoidCallback _authListener;

  int? _idUsuario;
  bool _loading = true;
  String? _error;

  List<EquipoUsuario> _equipos = const [];
  int? _selectedEquipoId;

  EloHistorialResponse? _eloResponse;
  RankingResponse? _rankingResponse;

  @override
  void initState() {
    super.initState();

    _authListener = () {
      if (!mounted) return;
      if (AuthState.isLoggedIn.value) {
        _loadInitial();
      } else {
        setState(() {
          _idUsuario = null;
          _equipos = const [];
          _selectedEquipoId = null;
          _eloResponse = null;
          _rankingResponse = null;
          _error = null;
          _loading = false;
        });
      }
    };

    AuthState.isLoggedIn.addListener(_authListener);

    if (AuthState.isLoggedIn.value) {
      _loadInitial();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    AuthState.isLoggedIn.removeListener(_authListener);
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await JwtStorage.getUser();
      final idUsuarioRaw = user?['id_usuario'];
      final idUsuario = (idUsuarioRaw is int)
          ? idUsuarioRaw
          : (idUsuarioRaw is num)
              ? idUsuarioRaw.toInt()
              : (idUsuarioRaw is String)
                  ? int.tryParse(idUsuarioRaw)
                  : null;

      if (idUsuario == null || idUsuario <= 0) {
        throw Exception('No se pudo resolver id_usuario (inicia sesión).');
      }

      final equiposRes = await _api.listEquiposUsuario(idUsuario);
      final equipos = equiposRes.data;

      int? selected;
      if (equipos.isNotEmpty) {
        final actual = equipos.where((e) => e.esActual).toList(growable: false);
        selected = (actual.isNotEmpty ? actual.first : equipos.first).idEquipo;
      }

      setState(() {
        _idUsuario = idUsuario;
        _equipos = equipos;
        _selectedEquipoId = selected;
      });

      if (selected != null) {
        await _loadEquipoData(selected);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadEquipoData(int idEquipo) async {
    final idUsuario = _idUsuario;
    if (idUsuario == null) return;

    setState(() {
      _error = null;
      _eloResponse = null;
      _rankingResponse = null;
    });

    try {
      final eloRes = await _api.getEloHistorial(idUsuario, equipoId: idEquipo);
      final rankingRes = await _api.getRanking(idUsuario, equipoId: idEquipo);

      if (!mounted) return;
      setState(() {
        _eloResponse = eloRes.data;
        _rankingResponse = rankingRes.data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthState.isLoggedIn.value) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Inicia sesión para ver tus estadísticas.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error: $_error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadInitial,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_equipos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No tienes equipos asociados todavía.'),
        ),
      );
    }

    final selectedId = _selectedEquipoId;
    final selectedEquipo = (selectedId == null)
        ? null
        : _equipos.where((e) => e.idEquipo == selectedId).firstOrNull;

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Dashboard',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Equipo', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: selectedId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.groups_outlined),
                      helperText: 'Selecciona el equipo para ver su ELO y ranking',
                    ),
                    items: _equipos
                        .map(
                          (e) => DropdownMenuItem<int>(
                            value: e.idEquipo,
                            child: Text(
                              e.esActual ? '${e.nombre} (actual)' : e.nombre,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() => _selectedEquipoId = value);
                      await _loadEquipoData(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _EloActualSummary(
            equipoNombre: selectedEquipo?.nombre ?? 'Equipo',
            eloActual: _eloResponse?.equipo.eloActual,
            points: _eloResponse?.historial ?? const [],
          ),
          const SizedBox(height: 16),
          _EloCard(
            equipoNombre: selectedEquipo?.nombre ?? 'Equipo',
            eloActual: _eloResponse?.equipo.eloActual,
            points: _eloResponse?.historial ?? const [],
          ),
          const SizedBox(height: 16),
          _RankingCard(
            ranking: _rankingResponse,
            selectedEquipoId: selectedId,
          ),
        ],
      ),
    );
  }
}

class _EloCard extends StatelessWidget {
  const _EloCard({
    required this.equipoNombre,
    required this.eloActual,
    required this.points,
  });

  final String equipoNombre;
  final int? eloActual;
  final List<EloPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final axisLabelStyle = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ELO - $equipoNombre',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (points.isEmpty)
              const Text('Sin historial de ELO para este equipo.')
            else
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: colors.outlineVariant,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => colors.surface,
                        tooltipRoundedRadius: 10,
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.x.round().clamp(0, points.length - 1);
                            final d = points[idx].creadoEn;
                            final dateLabel = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                            return LineTooltipItem(
                              '$dateLabel\nELO: ${spot.y.round()}',
                              theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ) ??
                                  TextStyle(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            );
                          }).toList(growable: false);
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: (points.length / 4).clamp(1, 9999).toDouble(),
                          getTitlesWidget: (value, meta) {
                            final index = value.round();
                            if (index < 0 || index >= points.length) {
                              return const SizedBox.shrink();
                            }
                            final d = points[index].creadoEn;
                            final label = '${d.day}/${d.month}';
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(label, style: axisLabelStyle),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(value.round().toString(), style: axisLabelStyle),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        barWidth: 3,
                        color: colors.primary,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colors.primary.withValues(alpha: 0.28),
                              colors.primary.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, _) {
                            final idx = spot.x.round();
                            return idx == 0 || idx == points.length - 1;
                          },
                          getDotPainter: (spot, _, __, ___) {
                            return FlDotCirclePainter(
                              radius: 3.2,
                              color: colors.primary,
                              strokeWidth: 2,
                              strokeColor: colors.surface,
                            );
                          },
                        ),
                        spots: List.generate(
                          points.length,
                          (i) => FlSpot(i.toDouble(), points[i].eloNuevo.toDouble()),
                        ),
                      ),
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

class _EloActualSummary extends StatelessWidget {
  const _EloActualSummary({
    required this.equipoNombre,
    required this.eloActual,
    required this.points,
  });

  final String equipoNombre;
  final int? eloActual;
  final List<EloPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final currentElo = eloActual ?? (points.isNotEmpty ? points.last.eloNuevo : null);
    final previousElo = points.length >= 2 ? points[points.length - 2].eloNuevo : null;

    final bool? wentUp = (currentElo == null || previousElo == null)
      ? null
      : currentElo > previousElo
        ? true
        : currentElo < previousElo
          ? false
          : null;

    final IconData trendIcon = (wentUp == null)
      ? Icons.trending_flat
      : wentUp
        ? Icons.trending_up
        : Icons.trending_down;

    final Color trendColor = (wentUp == null)
      ? colors.onSurfaceVariant
      : wentUp
        ? Colors.green
        : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ELO actual', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    equipoNombre,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    trendIcon,
                    size: 18,
                    color: trendColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentElo?.toString() ?? '—',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.ranking, required this.selectedEquipoId});

  final RankingResponse? ranking;
  final int? selectedEquipoId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = ranking;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clasificación', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (r == null)
              const Text('Cargando ranking...')
            else if (r.categoria == null)
              const Text('Sin categoría asociada todavía para este equipo.')
            else ...[
              Row(
                children: [
                  CategoriaNetworkAvatar(
                    categoriaId: r.categoria!.idCategoria,
                    baseUrl: ApiConfig.baseUrl,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Categoría: ${r.categoria!.nombre}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _RankingRow(
                entry: r.equipoUsuario,
                highlighted: true,
                labelOverride: 'Tu equipo',
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ...r.top10.map((e) {
                final isMine = selectedEquipoId != null && e.idEquipo == selectedEquipoId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RankingRow(entry: e, highlighted: isMine),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.entry,
    required this.highlighted,
    this.labelOverride,
  });

  final RankingEntry entry;
  final bool highlighted;
  final String? labelOverride;

  static Widget _medalLeading(BuildContext context, {required int position}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Sin hardcodear colores: usamos primarios del theme.
    final List<Color> gradientColors;
    final IconData medalIcon;

    switch (position) {
      case 1:
        gradientColors = <Color>[
          Colors.amber.shade200,
          Colors.amber,
          Colors.amber.shade700,
        ];
        medalIcon = Icons.workspace_premium;
        break;
      case 2:
        gradientColors = <Color>[
          Colors.grey.shade300,
          Colors.grey,
          Colors.grey.shade700,
        ];
        medalIcon = Icons.workspace_premium;
        break;
      case 3:
        gradientColors = <Color>[
          Colors.brown.shade200,
          Colors.brown,
          Colors.brown.shade700,
        ];
        medalIcon = Icons.workspace_premium;
        break;
      default:
        gradientColors = <Color>[colors.surfaceVariant, colors.surfaceVariant];
        medalIcon = Icons.workspace_premium;
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors
                    .map((c) => c.withValues(alpha: 0.22))
                    .toList(growable: false),
              ),
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ).createShader(bounds),
                child: Icon(
                  medalIcon,
                  size: 22,
                  color: colors.surface,
                ),
              ),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Text(
                position.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bg = highlighted ? colors.primaryContainer : colors.surface;
    final fg = highlighted ? colors.onPrimaryContainer : colors.onSurface;

    final pos = entry.posicion;
    final Widget leading = (pos == 1 || pos == 2 || pos == 3)
        ? _medalLeading(context, position: pos!)
        : SizedBox(
            width: 40,
            child: Text(
              pos?.toString() ?? '—',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(color: fg),
            ),
          );

    // "Sombreado entre posiciones": cada fila se renderiza como una mini-card
    // con elevación (shadow) y margen inferior para separar.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        elevation: highlighted ? 0 : 1.5,
        shadowColor: theme.shadowColor,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: highlighted ? Border.all(color: colors.primary, width: 1) : null,
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  labelOverride ?? entry.nombre,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: highlighted ? FontWeight.w700 : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (highlighted ? colors.primary : colors.surfaceVariant)
                      .withValues(alpha: highlighted ? 0.14 : 1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 16,
                      color: highlighted ? colors.primary : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.elo.toString(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: highlighted ? colors.primary : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
