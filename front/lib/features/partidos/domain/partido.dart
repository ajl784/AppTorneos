class Partido {
  final int idPartido;
  final int idTorneo;
  final String? torneoNombre;
  final String? fechaHora;
  final String? lugar;
  final String? estado;

  const Partido({
    required this.idPartido,
    required this.idTorneo,
    this.torneoNombre,
    this.fechaHora,
    this.lugar,
    this.estado,
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

  factory Partido.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(
      json['id_partido'] ?? json['idPartido'] ?? json['id'],
    );
    if (id == null) throw const FormatException('Partido sin id_partido');

    final idTorneo = _intOrNull(json['id_torneo'] ?? json['idTorneo']);
    if (idTorneo == null) throw const FormatException('Partido sin id_torneo');

    return Partido(
      idPartido: id,
      idTorneo: idTorneo,
      torneoNombre: _stringOrNull(
        json['torneo_nombre'] ?? json['torneoNombre'],
      ),
      fechaHora: _stringOrNull(json['fecha_hora'] ?? json['fechaHora']),
      lugar: _stringOrNull(json['lugar']),
      estado: _stringOrNull(json['estado']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_partido': idPartido,
    'id_torneo': idTorneo,
    'torneo_nombre': torneoNombre,
    'fecha_hora': fechaHora,
    'lugar': lugar,
    'estado': estado,
  };
}

class PartidoCreate {
  final int idTorneo;
  final String fechaHora;
  final String? lugar;
  final String? estado;

  const PartidoCreate({
    required this.idTorneo,
    required this.fechaHora,
    this.lugar,
    this.estado,
  });

  Map<String, dynamic> toJson() => {
    'id_torneo': idTorneo,
    'fecha_hora': fechaHora,
    if (lugar != null) 'lugar': lugar,
    if (estado != null) 'estado': estado,
  };
}

class PartidoUpdate {
  final int? idTorneo;
  final String? fechaHora;
  final String? lugar;
  final String? estado;

  const PartidoUpdate({this.idTorneo, this.fechaHora, this.lugar, this.estado});

  Map<String, dynamic> toJson() => {
    if (idTorneo != null) 'id_torneo': idTorneo,
    if (fechaHora != null) 'fecha_hora': fechaHora,
    if (lugar != null) 'lugar': lugar,
    if (estado != null) 'estado': estado,
  };
}

class PartidoPuntuacionItem {
  final int idParticipacionEquipo;
  final int? punto;
  final int? posicion;

  const PartidoPuntuacionItem({
    required this.idParticipacionEquipo,
    this.punto,
    this.posicion,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id_participacion_equipo': idParticipacionEquipo,
    };
    if (punto != null) data['punto'] = punto;
    if (posicion != null) data['posicion'] = posicion;
    return data;
  }
}

class RegistrarPuntuacionesPayload {
  final List<PartidoPuntuacionItem> puntuaciones;
  final int? idArbitroTorneo;
  final Object? acta;

  const RegistrarPuntuacionesPayload({
    required this.puntuaciones,
    this.idArbitroTorneo,
    this.acta,
  });

  Map<String, dynamic> toJson() => {
    'puntuaciones': puntuaciones.map((p) => p.toJson()).toList(growable: false),
    if (idArbitroTorneo != null) 'id_arbitro_torneo': idArbitroTorneo,
    if (acta != null) 'acta': acta,
  };
}

class RegistrarPuntuacionesResult {
  final int idPartido;
  final int idTorneo;
  final List<PuntuacionActualizada> puntuacionesActualizadas;
  final int? idArbitroTorneo;
  final bool? eloAplicado;
  final List<EloActualizado> eloActualizado;

  const RegistrarPuntuacionesResult({
    required this.idPartido,
    required this.idTorneo,
    required this.puntuacionesActualizadas,
    required this.idArbitroTorneo,
    required this.eloAplicado,
    required this.eloActualizado,
  });

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _boolOrNull(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }

  factory RegistrarPuntuacionesResult.fromJson(Map<String, dynamic> json) {
    final idPartido = _intOrNull(json['id_partido'] ?? json['idPartido']);
    final idTorneo = _intOrNull(json['id_torneo'] ?? json['idTorneo']);
    if (idPartido == null || idTorneo == null) {
      throw const FormatException('RegistrarPuntuacionesResult sin ids');
    }

    final actualizadasRaw = json['puntuaciones_actualizadas'];
    final actualizadas = (actualizadasRaw is List)
        ? actualizadasRaw
              .whereType<Map>()
              .map(
                (e) => PuntuacionActualizada.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(growable: false)
        : const <PuntuacionActualizada>[];

    final eloRaw = json['elo_actualizado'];
    final elo = (eloRaw is List)
        ? eloRaw
              .whereType<Map>()
              .map((e) => EloActualizado.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false)
        : const <EloActualizado>[];

    return RegistrarPuntuacionesResult(
      idPartido: idPartido,
      idTorneo: idTorneo,
      puntuacionesActualizadas: actualizadas,
      idArbitroTorneo: _intOrNull(
        json['id_arbitro_torneo'] ?? json['idArbitroTorneo'],
      ),
      eloAplicado: _boolOrNull(json['elo_aplicado'] ?? json['eloAplicado']),
      eloActualizado: elo,
    );
  }
}

class PuntuacionActualizada {
  final int idParticipacionEquipo;
  final int puntoPartido;
  final int puntuacionTorneo;

  const PuntuacionActualizada({
    required this.idParticipacionEquipo,
    required this.puntoPartido,
    required this.puntuacionTorneo,
  });

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory PuntuacionActualizada.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(
      json['id_participacion_equipo'] ?? json['idParticipacionEquipo'],
    );
    final puntoPartido = _intOrNull(
      json['punto_partido'] ?? json['puntoPartido'],
    );
    final puntuacionTorneo = _intOrNull(
      json['puntuacion_torneo'] ?? json['puntuacionTorneo'],
    );
    if (id == null || puntoPartido == null || puntuacionTorneo == null) {
      throw const FormatException('PuntuacionActualizada inválida');
    }

    return PuntuacionActualizada(
      idParticipacionEquipo: id,
      puntoPartido: puntoPartido,
      puntuacionTorneo: puntuacionTorneo,
    );
  }
}

class EloActualizado {
  final int idEquipo;
  final String? equipoNombre;
  final int? eloAnterior;
  final int? eloNuevo;
  final int? delta;

  const EloActualizado({
    required this.idEquipo,
    this.equipoNombre,
    this.eloAnterior,
    this.eloNuevo,
    this.delta,
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

  factory EloActualizado.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(json['id_equipo'] ?? json['idEquipo']);
    if (id == null) throw const FormatException('EloActualizado sin id_equipo');

    return EloActualizado(
      idEquipo: id,
      equipoNombre: _stringOrNull(
        json['equipo_nombre'] ?? json['equipoNombre'],
      ),
      eloAnterior: _intOrNull(json['elo_anterior'] ?? json['eloAnterior']),
      eloNuevo: _intOrNull(json['elo_nuevo'] ?? json['eloNuevo']),
      delta: _intOrNull(json['delta']),
    );
  }
}
