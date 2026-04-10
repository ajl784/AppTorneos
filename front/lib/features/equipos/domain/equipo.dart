class Equipo {
  final int idEquipo;
  final String nombre;
  final String? descripcion;
  final int? elo;

  const Equipo({
    required this.idEquipo,
    required this.nombre,
    this.descripcion,
    this.elo,
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

  factory Equipo.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(json['id_equipo'] ?? json['idEquipo'] ?? json['id']);
    if (id == null) {
      throw const FormatException('Equipo sin id_equipo');
    }

    return Equipo(
      idEquipo: id,
      nombre: (json['nombre'] as String?) ?? '',
      descripcion: _stringOrNull(json['descripcion']),
      elo: _intOrNull(json['elo']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_equipo': idEquipo,
      'nombre': nombre,
      'descripcion': descripcion,
      'elo': elo,
    };
  }
}

class EquipoCreate {
  final String nombre;
  final String? descripcion;
  final int? elo;

  const EquipoCreate({required this.nombre, this.descripcion, this.elo});

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    if (descripcion != null) 'descripcion': descripcion,
    if (elo != null) 'elo': elo,
  };
}

class EquipoUpdate {
  final String? nombre;
  final String? descripcion;
  final int? elo;

  const EquipoUpdate({this.nombre, this.descripcion, this.elo});

  Map<String, dynamic> toJson() => {
    if (nombre != null) 'nombre': nombre,
    if (descripcion != null) 'descripcion': descripcion,
    if (elo != null) 'elo': elo,
  };
}
