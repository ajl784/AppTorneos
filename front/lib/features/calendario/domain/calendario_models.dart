class CalendarioEquipo {
  final int idEquipo;
  final int idParticipacionEquipo;
  final String nombre;
  final bool esMiEquipo;
  final int puntoPartido;

  const CalendarioEquipo({
    required this.idEquipo,
    required this.idParticipacionEquipo,
    required this.nombre,
    required this.esMiEquipo,
    this.puntoPartido = 0,
  });

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _boolOrFalse(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return false;
  }

  factory CalendarioEquipo.fromJson(Map<String, dynamic> json) {
    final idEquipo = _intOrNull(json['id_equipo'] ?? json['idEquipo']);
    if (idEquipo == null) {
      throw const FormatException('CalendarioEquipo sin id_equipo');
    }

    final idParticipacionEquipo = _intOrNull(
      json['id_participacion_equipo'] ?? json['idParticipacionEquipo'],
    );
    if (idParticipacionEquipo == null) {
      throw const FormatException('CalendarioEquipo sin id_participacion_equipo');
    }

    final nombre = (json['nombre'] ?? '').toString();

    final puntoPartido = _intOrNull(
          json['punto_partido'] ?? json['puntoPartido'] ?? json['punto'],
        ) ??
        0;

    return CalendarioEquipo(
      idEquipo: idEquipo,
      idParticipacionEquipo: idParticipacionEquipo,
      nombre: nombre,
      esMiEquipo: _boolOrFalse(json['es_mi_equipo'] ?? json['esMiEquipo']),
      puntoPartido: puntoPartido,
    );
  }
}

class CalendarioPartido {
  final int idPartido;
  final int idTorneo;
  final String? torneoNombre;
  final DateTime fechaHora;
  final String? lugar;
  final String? estado;
  final int? jornada;
  final int? ronda;
  final int? ordenRonda;
  final List<CalendarioEquipo> equipos;
  final bool esJugador;
  final bool esArbitro;
  final String? arbitroNombre;
  final int? miIdArbitroTorneo;

  const CalendarioPartido({
    required this.idPartido,
    required this.idTorneo,
    required this.fechaHora,
    required this.equipos,
    this.torneoNombre,
    this.lugar,
    this.estado,
    this.jornada,
    this.ronda,
    this.ordenRonda,
    this.esJugador = false,
    this.esArbitro = false,
    this.arbitroNombre,
    this.miIdArbitroTorneo,
  });

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _boolOrFalse(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    if (value is num) return value != 0;
    return false;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        // Fallback común: "YYYY-MM-DD HH:MM:SS..." -> ISO-ish
        final normalized = value.replaceFirst(' ', 'T');
        return DateTime.parse(normalized);
      }
    }

    throw const FormatException('fecha_hora inválida');
  }

  factory CalendarioPartido.fromJson(Map<String, dynamic> json) {
    final idPartido = _intOrNull(json['id_partido'] ?? json['idPartido'] ?? json['id']);
    if (idPartido == null) {
      throw const FormatException('CalendarioPartido sin id_partido');
    }

    final idTorneo = _intOrNull(json['id_torneo'] ?? json['idTorneo']);
    if (idTorneo == null) {
      throw const FormatException('CalendarioPartido sin id_torneo');
    }

    final fechaHora = _parseDateTime(json['fecha_hora'] ?? json['fechaHora']);

    final equiposRaw = json['equipos'];
    final equipos = (equiposRaw is List)
        ? equiposRaw
            .whereType<Map>()
            .map((e) => CalendarioEquipo.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <CalendarioEquipo>[];

    return CalendarioPartido(
      idPartido: idPartido,
      idTorneo: idTorneo,
      torneoNombre: (json['torneo_nombre'] ?? json['torneoNombre'])?.toString(),
      fechaHora: fechaHora,
      lugar: json['lugar']?.toString(),
      estado: json['estado']?.toString(),
      jornada: _intOrNull(json['jornada']),
      ronda: _intOrNull(json['ronda']),
      ordenRonda: _intOrNull(json['orden_ronda'] ?? json['ordenRonda']),
      equipos: equipos,
      esJugador: _boolOrFalse(json['es_jugador'] ?? json['esJugador']),
      esArbitro: _boolOrFalse(json['es_arbitro'] ?? json['esArbitro']),
      arbitroNombre: (json['arbitro_nombre'] ?? json['arbitroNombre'])?.toString(),
      miIdArbitroTorneo: _intOrNull(json['mi_id_arbitro_torneo'] ?? json['miIdArbitroTorneo']),
    );
  }
}

class CalendarioUsuarioResponse {
  final int usuarioId;
  final String? desde;
  final String? hasta;
  final int total;
  final List<CalendarioPartido> partidos;

  const CalendarioUsuarioResponse({
    required this.usuarioId,
    required this.total,
    required this.partidos,
    this.desde,
    this.hasta,
  });

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory CalendarioUsuarioResponse.fromJson(Map<String, dynamic> json) {
    final usuarioId = _intOrNull(json['usuario_id'] ?? json['usuarioId']);
    if (usuarioId == null) {
      throw const FormatException('CalendarioUsuarioResponse sin usuario_id');
    }

    final partidosRaw = json['partidos'];
    final partidos = (partidosRaw is List)
        ? partidosRaw
            .whereType<Map>()
            .map((e) => CalendarioPartido.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <CalendarioPartido>[];

    return CalendarioUsuarioResponse(
      usuarioId: usuarioId,
      desde: json['desde']?.toString(),
      hasta: json['hasta']?.toString(),
      total: _intOrNull(json['total']) ?? partidos.length,
      partidos: partidos,
    );
  }
}
