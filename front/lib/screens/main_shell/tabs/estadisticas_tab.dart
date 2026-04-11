import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';

import 'package:front/features/estadisticas/data/estadisticas_api.dart';
import 'package:front/features/estadisticas/domain/estadisticas_models.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/state/jwt_storage.dart';

class EstadisticasTab extends StatefulWidget {
  const EstadisticasTab({super.key});

  @override
  State<EstadisticasTab> createState() => _EstadisticasTabState();
}

class _EstadisticasTabState extends State<EstadisticasTab> {
  final EstadisticasApi _api = EstadisticasApi(baseUrl: ApiConfig.baseUrl);

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
    _loadInitial();
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

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Equipo',
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedId,
                isExpanded: true,
                items: _equipos
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e.idEquipo,
                        child: Text(e.esActual ? '${e.nombre} (actual)' : e.nombre),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() => _selectedEquipoId = value);
                  await _loadEquipoData(value);
                },
              ),
            ),
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
    final axisLabelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface,
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
            const SizedBox(height: 6),
            Text(
              eloActual == null ? 'ELO actual: —' : 'ELO actual: $eloActual',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (points.isEmpty)
              const Text('Sin historial de ELO para este equipo.')
            else
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
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
                        isCurved: false,
                        barWidth: 3,
                        color: theme.colorScheme.primary,
                        dotData: const FlDotData(show: false),
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
              Text(
                'Categoría: ${r.categoria!.nombre}',
                style: theme.textTheme.bodyMedium,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = highlighted ? theme.colorScheme.primaryContainer : null;
    final fg = highlighted ? theme.colorScheme.onPrimaryContainer : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              entry.posicion?.toString() ?? '—',
              style: theme.textTheme.titleSmall?.copyWith(color: fg),
            ),
          ),
          Expanded(
            child: Text(
              labelOverride ?? entry.nombre,
              style: theme.textTheme.bodyMedium?.copyWith(color: fg),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            entry.elo.toString(),
            style: theme.textTheme.titleSmall?.copyWith(color: fg),
          ),
        ],
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
