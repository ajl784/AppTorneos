class TipoTorneo {
  final int idTipoTorneo;
  final String nombre;
  final String? descripcion;

  const TipoTorneo({
    required this.idTipoTorneo,
    required this.nombre,
    this.descripcion,
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

  factory TipoTorneo.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(json['id_tipo_torneo'] ?? json['idTipoTorneo']);
    if (id == null) {
      throw const FormatException('TipoTorneo sin id_tipo_torneo');
    }

    return TipoTorneo(
      idTipoTorneo: id,
      nombre: (json['nombre'] as String?) ?? '',
      descripcion: _stringOrNull(json['descripcion']),
    );
  }
}
