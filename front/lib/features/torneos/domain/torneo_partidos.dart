class TorneoPartidos {
  final int idTorneo;
  final String torneoNombre;
  final String? tipoTorneoNombre;
  final String? normaPuntuacion;
  final List<TorneoPartido> partidos;

  const TorneoPartidos({
    required this.idTorneo,
    required this.torneoNombre,
    required this.partidos,
    this.tipoTorneoNombre,
    this.normaPuntuacion,
  });

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  factory TorneoPartidos.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(json['id_torneo'] ?? json['idTorneo']);
    if (id == null) {
      throw const FormatException('Partidos sin id_torneo');
    }

    final rawItems = json['partidos'];
    final items = (rawItems is List)
        ? rawItems
            .whereType<Map>()
            .map((e) => TorneoPartido.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <TorneoPartido>[];

    return TorneoPartidos(
      idTorneo: id,
      torneoNombre: _stringOrNull(json['torneo_nombre'] ?? json['torneoNombre']) ??
          '',
      tipoTorneoNombre:
          _stringOrNull(json['tipo_torneo_nombre'] ?? json['tipoTorneoNombre']),
      normaPuntuacion: _stringOrNull(json['norma_puntuacion'] ?? json['normaPuntuacion']),
      partidos: items,
    );
  }
}

class TorneoPartido {
  final int idPartido;
  final String? fechaHora;
  final String? lugar;
  final String? estado;
  final int? jornada;
  final int? ronda;
  final int? ordenRonda;
  final int? ordenSerie;
  final int? idPartidoSiguiente;
  final int? ganadorIdParticipacionEquipo;
  final List<TorneoPartidoEquipo> equipos;

  const TorneoPartido({
    required this.idPartido,
    required this.equipos,
    this.fechaHora,
    this.lugar,
    this.estado,
    this.jornada,
    this.ronda,
    this.ordenRonda,
    this.ordenSerie,
    this.idPartidoSiguiente,
    this.ganadorIdParticipacionEquipo,
  });

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  factory TorneoPartido.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(json['id_partido'] ?? json['idPartido']);
    if (id == null) {
      throw const FormatException('Partido sin id_partido');
    }

    final rawEquipos = json['equipos'];
    final equipos = (rawEquipos is List)
        ? rawEquipos
            .whereType<Map>()
            .map((e) => TorneoPartidoEquipo.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList(growable: false)
        : const <TorneoPartidoEquipo>[];

    return TorneoPartido(
      idPartido: id,
      fechaHora: _stringOrNull(json['fecha_hora'] ?? json['fechaHora']),
      lugar: _stringOrNull(json['lugar']),
      estado: _stringOrNull(json['estado']),
      jornada: _intOrNull(json['jornada']),
      ronda: _intOrNull(json['ronda']),
      ordenRonda: _intOrNull(json['orden_ronda'] ?? json['ordenRonda']),
      ordenSerie: _intOrNull(json['orden_serie'] ?? json['ordenSerie']),
      idPartidoSiguiente:
          _intOrNull(json['id_partido_siguiente'] ?? json['idPartidoSiguiente']),
      ganadorIdParticipacionEquipo: _intOrNull(
        json['ganador_id_participacion_equipo'] ??
            json['ganadorIdParticipacionEquipo'],
      ),
      equipos: equipos,
    );
  }
}

class TorneoPartidoEquipo {
  final int idParticipacionEquipo;
  final int idEquipo;
  final String equipoNombre;
  final int punto;

  const TorneoPartidoEquipo({
    required this.idParticipacionEquipo,
    required this.idEquipo,
    required this.equipoNombre,
    required this.punto,
  });

  static int _intOrZero(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _stringOrEmpty(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  factory TorneoPartidoEquipo.fromJson(Map<String, dynamic> json) {
    return TorneoPartidoEquipo(
      idParticipacionEquipo:
          _intOrZero(json['id_participacion_equipo'] ?? json['idParticipacionEquipo']),
      idEquipo: _intOrZero(json['id_equipo'] ?? json['idEquipo']),
      equipoNombre:
          _stringOrEmpty(json['equipo_nombre'] ?? json['equipoNombre']),
      punto: _intOrZero(json['punto']),
    );
  }
}
