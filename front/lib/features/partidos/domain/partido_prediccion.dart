class PartidoPrediccion {
  final int idPartido;
  final String? fechaHora;
  final String? estado;
  final String metodo;
  final double scale;
  final String? cutoff;
  final List<PartidoPrediccionEquipo> equipos;

  const PartidoPrediccion({
    required this.idPartido,
    required this.metodo,
    required this.scale,
    required this.equipos,
    this.fechaHora,
    this.estado,
    this.cutoff,
  });

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double _doubleOrZero(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  factory PartidoPrediccion.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(json['id_partido'] ?? json['idPartido']);
    if (id == null) {
      throw const FormatException('Predicción sin id_partido');
    }

    final raw = json['equipos'];
    final equipos = (raw is List)
        ? raw
            .whereType<Map>()
            .map((e) => PartidoPrediccionEquipo.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList(growable: false)
        : const <PartidoPrediccionEquipo>[];

    return PartidoPrediccion(
      idPartido: id,
      fechaHora: _stringOrNull(json['fecha_hora'] ?? json['fechaHora']),
      estado: _stringOrNull(json['estado']),
      metodo: _stringOrNull(json['metodo']) ?? 'elo',
      scale: _doubleOrZero(json['scale']),
      cutoff: _stringOrNull(json['cutoff']),
      equipos: equipos,
    );
  }

  Map<int, double> probsByEquipoId() {
    final out = <int, double>{};
    for (final e in equipos) {
      if (e.idEquipo <= 0) continue;
      out[e.idEquipo] = e.probabilidadVictoria;
    }
    return out;
  }

  /// Returns probabilities for the provided team ids.
  ///
  /// - If all probabilities are 0 (or sum <= 0), returns an uniform split.
  /// - Otherwise normalizes probabilities so they sum to 1.0.
  Map<int, double> normalizedProbsForEquipoIds(Iterable<int> equipoIds) {
    final ids = equipoIds.where((id) => id > 0).toSet().toList(growable: false);
    if (ids.isEmpty) return const <int, double>{};

    final raw = probsByEquipoId();
    final values = <int, double>{
      for (final id in ids) id: (raw[id] ?? 0),
    };

    final sum = values.values.fold<double>(0, (acc, v) => acc + (v.isFinite ? v : 0));
    if (sum <= 0) {
      final u = 1.0 / ids.length;
      return <int, double>{for (final id in ids) id: u};
    }

    return <int, double>{
      for (final e in values.entries) e.key: (e.value.isFinite ? (e.value / sum) : 0),
    };
  }

  double? maxProb() {
    if (equipos.isEmpty) return null;
    double? maxV;
    for (final e in equipos) {
      final v = e.probabilidadVictoria;
      maxV = maxV == null ? v : (v > maxV ? v : maxV);
    }
    return maxV;
  }
}

class PartidoPrediccionEquipo {
  final int idEquipo;
  final String? nombre;
  final double elo;
  final double probabilidadVictoria;

  const PartidoPrediccionEquipo({
    required this.idEquipo,
    required this.elo,
    required this.probabilidadVictoria,
    this.nombre,
  });

  static int _intOrZero(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _doubleOrZero(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  factory PartidoPrediccionEquipo.fromJson(Map<String, dynamic> json) {
    return PartidoPrediccionEquipo(
      idEquipo: _intOrZero(json['id_equipo'] ?? json['idEquipo']),
      nombre: _stringOrNull(json['nombre'] ?? json['equipo_nombre'] ?? json['equipoNombre']),
      elo: _doubleOrZero(json['elo']),
      probabilidadVictoria: _doubleOrZero(
        json['probabilidad_victoria'] ?? json['probabilidadVictoria'],
      ),
    );
  }
}
