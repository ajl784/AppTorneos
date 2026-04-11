import 'package:flutter/material.dart';

import 'package:table_calendar/table_calendar.dart';

import 'package:front/features/calendario/data/calendario_api.dart';
import 'package:front/features/calendario/domain/calendario_models.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/state/jwt_storage.dart';

class CalendarioTab extends StatefulWidget {
  const CalendarioTab({super.key});

  @override
  State<CalendarioTab> createState() => _CalendarioTabState();
}

class _CalendarioTabState extends State<CalendarioTab> {
  final CalendarioApi _api = CalendarioApi(baseUrl: ApiConfig.baseUrl);

  bool _loading = true;
  String? _error;
  int? _idUsuario;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<CalendarioPartido>> _eventsByDay = {};
  DateTime? _loadedMonthKey;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  static DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _monthKey(DateTime d) => DateTime(d.year, d.month);

  static DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  static DateTime _endOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0);

  static String _toYmd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
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

      setState(() {
        _idUsuario = idUsuario;
        _selectedDay = _dayKey(DateTime.now());
      });

      await _loadMonth(_focusedDay);
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

  Future<void> _loadMonth(DateTime focused) async {
    final idUsuario = _idUsuario;
    if (idUsuario == null) return;

    final monthKey = _monthKey(focused);
    if (_loadedMonthKey == monthKey && _eventsByDay.isNotEmpty) {
      return;
    }

    setState(() {
      _error = null;
    });

    try {
      final desde = _toYmd(_startOfMonth(focused));
      final hasta = _toYmd(_endOfMonth(focused));

      final res = await _api.getCalendarioUsuario(
        idUsuario,
        desde: desde,
        hasta: hasta,
        limit: 200,
        offset: 0,
      );

      final eventos = <DateTime, List<CalendarioPartido>>{};
      for (final partido in res.data.partidos) {
        final key = _dayKey(partido.fechaHora.toLocal());
        (eventos[key] ??= <CalendarioPartido>[]).add(partido);
      }

      // Ordena por hora dentro del día
      for (final entry in eventos.entries) {
        entry.value.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
      }

      if (!mounted) return;
      setState(() {
        _eventsByDay
          ..clear()
          ..addAll(eventos);
        _loadedMonthKey = monthKey;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  List<CalendarioPartido> _eventsForDay(DateTime day) {
    return _eventsByDay[_dayKey(day)] ?? const <CalendarioPartido>[];
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

    final selected = _selectedDay;
    final eventsSelected = selected == null ? const <CalendarioPartido>[] : _eventsForDay(selected);

    return RefreshIndicator(
      onRefresh: () async {
        _loadedMonthKey = null;
        await _loadMonth(_focusedDay);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Calendario',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TableCalendar<CalendarioPartido>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) => selected != null && isSameDay(selected, day),
                eventLoader: _eventsForDay,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = _dayKey(selectedDay);
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) async {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  await _loadMonth(focusedDay);
                },
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Partidos del día',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (selected == null)
            const Text('Selecciona un día para ver partidos.')
          else if (eventsSelected.isEmpty)
            const Text('Sin partidos para este día.')
          else
            ...eventsSelected.map((p) => _PartidoItem(partido: p)).toList(growable: false),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PartidoItem extends StatelessWidget {
  const _PartidoItem({required this.partido});

  final CalendarioPartido partido;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = partido.fechaHora.toLocal();
    final timeLabel = TimeOfDay.fromDateTime(local).format(context);

    final misEquipos = partido.equipos.where((e) => e.esMiEquipo).map((e) => e.nombre).toList(growable: false);
    final rivales = partido.equipos.where((e) => !e.esMiEquipo).map((e) => e.nombre).toList(growable: false);

    final torneo = (partido.torneoNombre == null || partido.torneoNombre!.trim().isEmpty)
        ? 'Torneo #${partido.idTorneo}'
        : partido.torneoNombre!;

    final estado = partido.estado ?? '—';
    final lugar = partido.lugar;

    final roundLabel = (partido.jornada != null)
      ? 'Jornada ${partido.jornada}'
      : (partido.ronda != null)
        ? 'Ronda ${partido.ronda}${partido.ordenRonda != null ? ' · #${partido.ordenRonda}' : ''}'
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(timeLabel, style: theme.textTheme.titleMedium),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    torneo,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Estado: $estado', style: theme.textTheme.bodyMedium),
            if (roundLabel != null)
              Text(roundLabel, style: theme.textTheme.bodyMedium),
            if (lugar != null && lugar.trim().isNotEmpty)
              Text('Lugar: $lugar', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            if (misEquipos.isNotEmpty)
              Text('Mis equipos: ${misEquipos.join(' · ')}', style: theme.textTheme.bodySmall),
            if (rivales.isNotEmpty)
              Text('Rivales: ${rivales.join(' · ')}', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
