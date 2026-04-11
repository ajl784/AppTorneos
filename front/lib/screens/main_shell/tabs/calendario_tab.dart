import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../features/torneos/domain/torneo.dart';
import '../../../features/torneos/data/torneos_api.dart';
import '../../../peticion/api_config.dart';

class CalendarioTab extends StatefulWidget {
  const CalendarioTab({super.key});

  @override
  State<CalendarioTab> createState() => _CalendarioTabState();
}

class _CalendarioTabState extends State<CalendarioTab> {
  late Future<List<Torneo>> _torneosFuture;
  Map<DateTime, List<Torneo>> _torneosPorFecha = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final TorneosApi _api = TorneosApi(baseUrl: ApiConfig.baseUrl);


  @override
  void initState() {
    super.initState();
    _torneosFuture = _cargarTorneosDesdeApi();
  }

  Future<List<Torneo>> _cargarTorneosDesdeApi() async {
    final torneos = await _api.fetchTorneos();
    _torneosPorFecha = {};
    for (final torneo in torneos) {
      if (torneo.fechaInicio != null && torneo.fechaInicio!.isNotEmpty) {
        final fecha = DateTime.tryParse(torneo.fechaInicio!);
        if (fecha != null) {
          final key = DateTime(fecha.year, fecha.month, fecha.day);
          _torneosPorFecha.putIfAbsent(key, () => []).add(torneo);
        }
      }
    }
    return torneos;
  }

  List<Torneo> _getTorneosDelDia(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _torneosPorFecha[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Torneo>>(
      future: _torneosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar torneos'));
        }
        return Column(
          children: [
            TableCalendar<Torneo>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getTorneosDelDia,
              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _selectedDay == null || _getTorneosDelDia(_selectedDay!).isEmpty
                  ? const Center(child: Text('No hay torneos para este día'))
                  : ListView.builder(
                      itemCount: _getTorneosDelDia(_selectedDay!).length,
                      itemBuilder: (context, index) {
                        final torneo = _getTorneosDelDia(_selectedDay!)[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            title: Text(torneo.nombre),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (torneo.fechaInicio != null)
                                  Text('Fecha inicio: ${torneo.fechaInicio}'),
                                if (torneo.fechaFin != null)
                                  Text('Fecha fin: ${torneo.fechaFin}'),
                                if (torneo.estado != null)
                                  Text('Estado: ${torneo.estado}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
