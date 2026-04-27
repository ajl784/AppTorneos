class Torneo {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? fechaInicio;
  final String? fechaFin;
  final String? estado;
  final int? limiteEquipos;
  final int? categoriaId;
  final String? categoriaNombre;
  final String? categoriaNorma;
  final int? tipoTorneoId;
  final String? tipoTorneoNombre;
  final int? organizadorId;
  final int? participantesPorPartido;
  final Object? encuesta;
  final String? normaPuntuacion;
  final Object? preferenciaHorario;
  final String? tipoGeneracionEnfrentamientos;

  const Torneo({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.fechaInicio,
    this.fechaFin,
    this.estado,
    this.limiteEquipos,
    this.categoriaId,
    this.categoriaNombre,
    this.categoriaNorma,
    this.tipoTorneoId,
    this.tipoTorneoNombre,
    this.organizadorId,
    this.participantesPorPartido,
    this.encuesta,
    this.normaPuntuacion,
    this.preferenciaHorario,
    this.tipoGeneracionEnfrentamientos,
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

  factory Torneo.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(json['id']) ?? _intOrNull(json['id_torneo']);
    if (id == null) {
      throw const FormatException('Torneo sin id/id_torneo');
    }

    return Torneo(
      id: id,
      nombre: (json['nombre'] as String?) ?? '',
      descripcion: _stringOrNull(json['descripcion']),
      fechaInicio: _stringOrNull(json['fecha_inicio'] ?? json['fechaInicio']),
      fechaFin: _stringOrNull(json['fecha_fin'] ?? json['fechaFin']),
      estado: _stringOrNull(json['estado']),
      limiteEquipos: _intOrNull(
        json['limite_equipos'] ?? json['limiteEquipos'],
      ),
      categoriaId: _intOrNull(json['id_categoria'] ?? json['categoriaId']),
      categoriaNombre: _stringOrNull(
        json['categoria_nombre'] ?? json['categoriaNombre'],
      ),
      categoriaNorma: _stringOrNull(
        json['categoria_norma'] ?? json['categoriaNorma'],
      ),
      tipoTorneoId: _intOrNull(json['id_tipo_torneo'] ?? json['tipoTorneoId']),
      tipoTorneoNombre: _stringOrNull(
        json['tipo_torneo_nombre'] ?? json['tipoTorneoNombre'],
      ),
      organizadorId: _intOrNull(
        json['id_organizador'] ?? json['organizadorId'],
      ),
      participantesPorPartido: _intOrNull(
        json['participantes_por_partido'] ?? json['participantesPorPartido'],
      ),
      encuesta: json['encuesta'],
      normaPuntuacion: _stringOrNull(
        json['norma_puntuacion'] ?? json['normaPuntuacion'],
      ),
      preferenciaHorario:
          json['preferencia_horario'] ?? json['preferenciaHorario'],
      tipoGeneracionEnfrentamientos: _stringOrNull(
        json['tipo_generacion_enfrentamientos'] ??
            json['tipoGeneracionEnfrentamientos'],
      ),
    );
  }
}

class TorneoCreate {
  final String nombre;
  final String? descripcion;
  final String? fechaInicio;
  final String? fechaFin;
  final String? estado;
  final int? limiteEquipos;
  final int idCategoria;
  final int idTipoTorneo;
  final int? idOrganizador;
  final Object? encuesta;
  final String? normaPuntuacion;
  final Object? preferenciaHorario;
  final String? tipoGeneracionEnfrentamientos;

  const TorneoCreate({
    required this.nombre,
    required this.idCategoria,
    required this.idTipoTorneo,
    this.descripcion,
    this.fechaInicio,
    this.fechaFin,
    this.estado,
    this.limiteEquipos,
    this.idOrganizador,
    this.encuesta,
    this.normaPuntuacion,
    this.preferenciaHorario,
    this.tipoGeneracionEnfrentamientos,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    if (descripcion != null) 'descripcion': descripcion,
    if (fechaInicio != null) 'fecha_inicio': fechaInicio,
    if (fechaFin != null) 'fecha_fin': fechaFin,
    if (estado != null) 'estado': estado,
    if (limiteEquipos != null) 'limite_equipos': limiteEquipos,
    'id_categoria': idCategoria,
    'id_tipo_torneo': idTipoTorneo,
    if (idOrganizador != null) 'id_organizador': idOrganizador,
    if (encuesta != null) 'encuesta': encuesta,
    if (normaPuntuacion != null) 'norma_puntuacion': normaPuntuacion,
    if (preferenciaHorario != null) 'preferencia_horario': preferenciaHorario,
    if (tipoGeneracionEnfrentamientos != null)
      'tipo_generacion_enfrentamientos': tipoGeneracionEnfrentamientos,
  };
}

class TorneoUpdate {
  final String? nombre;
  final String? descripcion;
  final String? fechaInicio;
  final String? fechaFin;
  final String? estado;
  final int? limiteEquipos;
  final int? idCategoria;
  final int? idTipoTorneo;
  final int? idOrganizador;
  final Object? encuesta;
  final String? normaPuntuacion;
  final Object? preferenciaHorario;
  final String? tipoGeneracionEnfrentamientos;

  const TorneoUpdate({
    this.nombre,
    this.descripcion,
    this.fechaInicio,
    this.fechaFin,
    this.estado,
    this.limiteEquipos,
    this.idCategoria,
    this.idTipoTorneo,
    this.idOrganizador,
    this.encuesta,
    this.normaPuntuacion,
    this.preferenciaHorario,
    this.tipoGeneracionEnfrentamientos,
  });

  Map<String, dynamic> toJson() => {
    if (nombre != null) 'nombre': nombre,
    if (descripcion != null) 'descripcion': descripcion,
    if (fechaInicio != null) 'fecha_inicio': fechaInicio,
    if (fechaFin != null) 'fecha_fin': fechaFin,
    if (estado != null) 'estado': estado,
    if (limiteEquipos != null) 'limite_equipos': limiteEquipos,
    if (idCategoria != null) 'id_categoria': idCategoria,
    if (idTipoTorneo != null) 'id_tipo_torneo': idTipoTorneo,
    if (idOrganizador != null) 'id_organizador': idOrganizador,
    if (encuesta != null) 'encuesta': encuesta,
    if (normaPuntuacion != null) 'norma_puntuacion': normaPuntuacion,
    if (preferenciaHorario != null) 'preferencia_horario': preferenciaHorario,
    if (tipoGeneracionEnfrentamientos != null)
      'tipo_generacion_enfrentamientos': tipoGeneracionEnfrentamientos,
  };
}
