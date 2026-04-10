class Participacion {
  final int idParticipacionEquipo;
  final int idTorneo;
  final String? torneoNombre;
  final int idEquipo;
  final String? equipoNombre;
  final String? fecha;
  final Object? respuesta;
  final String? estado;
  final int? puntuacion;

  const Participacion({
    required this.idParticipacionEquipo,
    required this.idTorneo,
    required this.idEquipo,
    this.torneoNombre,
    this.equipoNombre,
    this.fecha,
    this.respuesta,
    this.estado,
    this.puntuacion,
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

  factory Participacion.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(
      json['id_participacion_equipo'] ??
          json['idParticipacionEquipo'] ??
          json['id'],
    );
    if (id == null) {
      throw const FormatException('Participacion sin id_participacion_equipo');
    }

    final idTorneo = _intOrNull(json['id_torneo'] ?? json['idTorneo']);
    final idEquipo = _intOrNull(json['id_equipo'] ?? json['idEquipo']);
    if (idTorneo == null || idEquipo == null) {
      throw const FormatException('Participacion sin id_torneo/id_equipo');
    }

    return Participacion(
      idParticipacionEquipo: id,
      idTorneo: idTorneo,
      torneoNombre: _stringOrNull(
        json['torneo_nombre'] ?? json['torneoNombre'],
      ),
      idEquipo: idEquipo,
      equipoNombre: _stringOrNull(
        json['equipo_nombre'] ?? json['equipoNombre'],
      ),
      fecha: _stringOrNull(json['fecha']),
      respuesta: json['respuesta'],
      estado: _stringOrNull(json['estado']),
      puntuacion: _intOrNull(json['puntuacion']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_participacion_equipo': idParticipacionEquipo,
    'id_torneo': idTorneo,
    'torneo_nombre': torneoNombre,
    'id_equipo': idEquipo,
    'equipo_nombre': equipoNombre,
    'fecha': fecha,
    'respuesta': respuesta,
    'estado': estado,
    'puntuacion': puntuacion,
  };
}

class ParticipacionCreate {
  final int idTorneo;
  final int idEquipo;
  final Object? respuesta;
  final String? estado;
  final int? puntuacion;

  const ParticipacionCreate({
    required this.idTorneo,
    required this.idEquipo,
    this.respuesta,
    this.estado,
    this.puntuacion,
  });

  Map<String, dynamic> toJson() => {
    'id_torneo': idTorneo,
    'id_equipo': idEquipo,
    if (respuesta != null) 'respuesta': respuesta,
    if (estado != null) 'estado': estado,
    if (puntuacion != null) 'puntuacion': puntuacion,
  };
}

class ParticipacionUpdate {
  final int? idTorneo;
  final int? idEquipo;
  final Object? respuesta;
  final String? estado;
  final int? puntuacion;

  const ParticipacionUpdate({
    this.idTorneo,
    this.idEquipo,
    this.respuesta,
    this.estado,
    this.puntuacion,
  });

  Map<String, dynamic> toJson() => {
    if (idTorneo != null) 'id_torneo': idTorneo,
    if (idEquipo != null) 'id_equipo': idEquipo,
    if (respuesta != null) 'respuesta': respuesta,
    if (estado != null) 'estado': estado,
    if (puntuacion != null) 'puntuacion': puntuacion,
  };
}

class SolicitudCreate {
  final int idEquipo;
  final Object respuesta;

  const SolicitudCreate({required this.idEquipo, required this.respuesta});

  Map<String, dynamic> toJson() => {
    'id_equipo': idEquipo,
    'respuesta': respuesta,
  };
}

class DecisionSolicitudPayload {
  final bool aceptar;

  const DecisionSolicitudPayload({required this.aceptar});

  Map<String, dynamic> toJson() => {'aceptar': aceptar};
}
