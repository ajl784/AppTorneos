class Torneo {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? fechaInicio;
  final String? fechaFin;
  final String? estado;
  final int? categoriaId;
  final String? categoriaNombre;
  final int? tipoTorneoId;
  final String? tipoTorneoNombre;
  final int? organizadorId;

  const Torneo({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.fechaInicio,
    this.fechaFin,
    this.estado,
    this.categoriaId,
    this.categoriaNombre,
    this.tipoTorneoId,
    this.tipoTorneoNombre,
    this.organizadorId,
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
      categoriaId: _intOrNull(json['id_categoria'] ?? json['categoriaId']),
      categoriaNombre: _stringOrNull(
        json['categoria_nombre'] ?? json['categoriaNombre'],
      ),
      tipoTorneoId: _intOrNull(json['id_tipo_torneo'] ?? json['tipoTorneoId']),
      tipoTorneoNombre: _stringOrNull(
        json['tipo_torneo_nombre'] ?? json['tipoTorneoNombre'],
      ),
      organizadorId: _intOrNull(json['id_organizador'] ?? json['organizadorId']),
    );
  }
}
