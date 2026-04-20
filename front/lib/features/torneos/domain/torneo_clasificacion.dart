class TorneoClasificacion {
  final int idTorneo;
  final String torneoNombre;
  final String? tipoTorneoNombre;
  final String? normaPuntuacion;
  final List<TorneoClasificacionItem> clasificacion;

  const TorneoClasificacion({
    required this.idTorneo,
    required this.torneoNombre,
    required this.clasificacion,
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

  factory TorneoClasificacion.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(json['id_torneo'] ?? json['idTorneo']);
    if (id == null) {
      throw const FormatException('Clasificación sin id_torneo');
    }

    final rawItems = json['clasificacion'];
    final items = (rawItems is List)
        ? rawItems
            .whereType<Map>()
            .map((e) => TorneoClasificacionItem.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList(growable: false)
        : const <TorneoClasificacionItem>[];

    return TorneoClasificacion(
      idTorneo: id,
      torneoNombre: _stringOrNull(json['torneo_nombre'] ?? json['torneoNombre']) ??
          '',
      tipoTorneoNombre:
          _stringOrNull(json['tipo_torneo_nombre'] ?? json['tipoTorneoNombre']),
      normaPuntuacion:
          _stringOrNull(json['norma_puntuacion'] ?? json['normaPuntuacion']),
      clasificacion: items,
    );
  }
}

class TorneoClasificacionItem {
  final int posicion;
  final int idEquipo;
  final String equipoNombre;
  final int elo;
  final num puntos;

  const TorneoClasificacionItem({
    required this.posicion,
    required this.idEquipo,
    required this.equipoNombre,
    required this.elo,
    required this.puntos,
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

  factory TorneoClasificacionItem.fromJson(Map<String, dynamic> json) {
    return TorneoClasificacionItem(
      posicion: _intOrZero(json['posicion']),
      idEquipo: _intOrZero(json['id_equipo'] ?? json['idEquipo']),
      equipoNombre: _stringOrEmpty(
        json['equipo_nombre'] ?? json['equipoNombre'],
      ),
      elo: _intOrZero(json['elo']),
      puntos: (json['puntos'] is num)
          ? (json['puntos'] as num)
          : num.tryParse(json['puntos']?.toString() ?? '0') ?? 0,
    );
  }
}
