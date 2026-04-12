import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:front/features/calendario/data/calendario_api.dart';
import 'package:front/features/calendario/domain/calendario_models.dart';
import 'package:front/features/partidos/data/partidos_api.dart';
import 'package:front/features/partidos/domain/partido.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/features/torneos/domain/torneo.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/state/auth_state.dart';
import 'package:front/state/jwt_storage.dart';

class CalendarioTab extends StatefulWidget {
  const CalendarioTab({super.key});

  @override
  State<CalendarioTab> createState() => _CalendarioTabState();
}

class _CalendarioTabState extends State<CalendarioTab> {
  final CalendarioApi _api = CalendarioApi(baseUrl: ApiConfig.baseUrl);
  final PartidosApi _partidosApi = PartidosApi(baseUrl: ApiConfig.baseUrl);
  final TorneosApi _torneosApi = TorneosApi(baseUrl: ApiConfig.baseUrl);

  late final VoidCallback _authListener;

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

    _authListener = () {
      if (!mounted) return;
      if (AuthState.isLoggedIn.value) {
        _loadInitial();
      } else {
        setState(() {
          _idUsuario = null;
          _error = null;
          _loading = false;
          _selectedDay = null;
          _eventsByDay.clear();
          _loadedMonthKey = null;
          _focusedDay = DateTime.now();
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

  static ({int victoria, int empate, int derrota})? _parseNormaPuntuacion(
    String? norma,
  ) {
    final raw = (norma ?? '').trim();
    if (raw.isEmpty) return null;
    final parts = raw
        .split(RegExp(r'[^0-9]+'))
        .where((p) => p.trim().isNotEmpty)
        .map(int.tryParse)
        .whereType<int>()
        .toList(growable: false);
    if (parts.length != 3) return null;
    return (victoria: parts[0], empate: parts[1], derrota: parts[2]);
  }

  Future<void> _openEditarPartidoDialog(CalendarioPartido partido) async {
    final estados = const <String>[
      'planificado',
      'en_curso',
      'acabado',
      'cancelado',
    ];

    var selectedEstado = (partido.estado ?? 'planificado').trim();
    if (!estados.contains(selectedEstado)) {
      selectedEstado = 'planificado';
    }

    final scoreControllers = <int, TextEditingController>{
      for (final e in partido.equipos)
        e.idParticipacionEquipo: TextEditingController(
          text: e.puntoPartido.toString(),
        ),
    };

    Torneo? torneo;
    String? torneosError;
    try {
      torneo = await _torneosApi.fetchTorneoById(partido.idTorneo);
    } catch (e) {
      torneosError = e.toString();
    }

    if (!mounted) {
      for (final c in scoreControllers.values) {
        c.dispose();
      }
      return;
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final normaParsed = _parseNormaPuntuacion(torneo?.normaPuntuacion);
            return AlertDialog(
              title: Text('Editar Partido #${partido.idPartido}'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedEstado,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: estados
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (v) {
                        if (v == null) return;
                        setStateDialog(() => selectedEstado = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Marcador del partido (se guarda al pasar a "acabado"):',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'La clasificación del torneo (ej. 3-1-0) se calcula automáticamente según la regla de puntuación.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    ...partido.equipos.map((e) {
                      final c = scoreControllers[e.idParticipacionEquipo]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextFormField(
                          controller: c,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: e.nombre,
                            hintText: '0',
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Text(
                      'Descripción del torneo:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    if (torneosError != null)
                      Text(
                        'No se pudieron cargar: $torneosError',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.error),
                      )
                    else
                      Text(
                        (() {
                          final txt = torneo?.descripcion?.trim();
                          if (txt == null || txt.isEmpty) return '—';
                          return txt;
                        })(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Normas de la categoría:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    if (torneosError != null)
                      Text(
                        'No se pudieron cargar: $torneosError',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.error),
                      )
                    else ...[
                      // Normalizamos textos por si vienen null o vacíos
                      // (y para evitar non-null assertions innecesarias).
                      //
                      // Nota: no guardamos esto en state; es solo para UI.
                      Text(
                        (() {
                          final txt = torneo?.categoriaNorma?.trim();
                          if (txt == null || txt.isEmpty) return '—';
                          return txt;
                        })(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Regla de puntuación:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        normaParsed == null
                            ? (() {
                                final txt = torneo?.normaPuntuacion?.trim();
                                if (txt == null || txt.isEmpty) return '—';
                                return txt;
                              })()
                            : 'Victoria ${normaParsed.victoria} · Empate ${normaParsed.empate} · Derrota ${normaParsed.derrota}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) {
      for (final c in scoreControllers.values) {
        c.dispose();
      }
      return;
    }

    final scoresByParticipacion = <int, int>{
      for (final e in partido.equipos)
        e.idParticipacionEquipo: () {
          final raw = scoreControllers[e.idParticipacionEquipo]?.text ?? '0';
          final punto = int.tryParse(raw.trim()) ?? 0;
          return punto < 0 ? 0 : punto;
        }(),
    };

    for (final c in scoreControllers.values) {
      c.dispose();
    }

    try {
      await _partidosApi.updatePartido(
        partido.idPartido,
        PartidoUpdate(estado: selectedEstado),
      );

      if (selectedEstado == 'acabado') {
        final items = partido.equipos.map((e) {
          return PartidoPuntuacionItem(
            idParticipacionEquipo: e.idParticipacionEquipo,
            punto: scoresByParticipacion[e.idParticipacionEquipo] ?? 0,
          );
        }).toList(growable: false);

        await _partidosApi.registrarPuntuacionesArbitro(
          idPartido: partido.idPartido,
          payload: RegistrarPuntuacionesPayload(
            puntuaciones: items,
            idArbitroTorneo: partido.miIdArbitroTorneo,
            acta: null,
          ),
        );
      }

      if (!mounted) return;
      _loadedMonthKey = null;
      await _loadMonth(_focusedDay);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
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

  Future<void> _showPartidosDiaDialog(
    BuildContext context, {
    required DateTime day,
    required List<CalendarioPartido> partidos,
  }) async {
    final d = _dayKey(day);
    final title = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().padLeft(4, '0')}';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Partidos · $title'),
          content: SizedBox(
            width: double.maxFinite,
            child: partidos.isEmpty
                ? const Text('Sin partidos para este día.')
                : ListView(
                    shrinkWrap: true,
                    children: partidos
                        .map(
                          (p) => _PartidoItem(
                            partido: p,
                            onEditar: p.esArbitro
                                ? () => _openEditarPartidoDialog(p)
                                : null,
                          ),
                        )
                        .toList(growable: false),
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
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthState.isLoggedIn.value) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Inicia sesión para ver tu calendario.',
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
                selectedDayPredicate: (day) => _selectedDay != null && isSameDay(_selectedDay, day),
                eventLoader: _eventsForDay,
                onDaySelected: (selectedDay, focusedDay) {
                  final events = _eventsForDay(selectedDay);
                  setState(() {
                    _selectedDay = _dayKey(selectedDay);
                    _focusedDay = focusedDay;
                  });

                  // Solo abre el pop-up si el día tiene partidos (punto).
                  if (events.isNotEmpty) {
                    _showPartidosDiaDialog(
                      context,
                      day: selectedDay,
                      partidos: events,
                    );
                  }
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PartidoItem extends StatelessWidget {
  const _PartidoItem({required this.partido, this.onEditar});

  final CalendarioPartido partido;
  final VoidCallback? onEditar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = partido.fechaHora.toLocal();
    final timeLabel = TimeOfDay.fromDateTime(local).format(context);

    final misEquipos = partido.equipos.where((e) => e.esMiEquipo).map((e) => e.nombre).toList(growable: false);
    final rivales = partido.equipos.where((e) => !e.esMiEquipo).map((e) => e.nombre).toList(growable: false);
    final equiposLabel = partido.equipos.map((e) => e.nombre).toList(growable: false);

    final torneo = (partido.torneoNombre == null || partido.torneoNombre!.trim().isEmpty)
        ? 'Torneo #${partido.idTorneo}'
        : partido.torneoNombre!;

    final estado = partido.estado ?? '—';
    final lugar = partido.lugar;
    final arbitroNombre = (partido.arbitroNombre == null || partido.arbitroNombre!.trim().isEmpty)
      ? null
      : partido.arbitroNombre!.trim();

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
            if (partido.esArbitro || partido.esJugador) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: -8,
                children: [
                  if (partido.esArbitro)
                    const Chip(
                      label: Text('Arbitras'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )
                  else
                    const Chip(
                      label: Text('Juegas'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Text('Partido #${partido.idPartido}', style: theme.textTheme.bodyMedium),
            Text('Estado: $estado', style: theme.textTheme.bodyMedium),
            if (roundLabel != null)
              Text(roundLabel, style: theme.textTheme.bodyMedium),
            if (lugar != null && lugar.trim().isNotEmpty)
              Text('Lugar: $lugar', style: theme.textTheme.bodyMedium),
            Text(
              'Árbitro: ${arbitroNombre ?? '—'}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            if (equiposLabel.isNotEmpty)
              Text('Equipos: ${equiposLabel.join(' · ')}', style: theme.textTheme.bodySmall),
            if (misEquipos.isNotEmpty)
              Text('Mis equipos: ${misEquipos.join(' · ')}', style: theme.textTheme.bodySmall),
            if (misEquipos.isNotEmpty && rivales.isNotEmpty)
              Text('Rivales: ${rivales.join(' · ')}', style: theme.textTheme.bodySmall),

            if (partido.esArbitro && onEditar != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Este item se muestra dentro del diálogo del día.
                    // Si editamos y guardamos, el diálogo seguiría mostrando
                    // la lista vieja (capturada), aunque el calendario se recargue.
                    // Cerramos el diálogo del día y luego abrimos el editor.
                    Navigator.of(context).pop();
                    Future.microtask(() => onEditar?.call());
                  },
                  child: const Text('Editar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
