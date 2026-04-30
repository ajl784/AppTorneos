class Equipo {
  final int idEquipo;
  final String nombre;
  final String? descripcion;
  final int? elo;
  final int? idCategoria;
  final String? categoriaNombre;
  final String? iconoUrl;

  const Equipo({
    required this.idEquipo,
    required this.nombre,
    this.descripcion,
    this.elo,
    this.idCategoria,
    this.categoriaNombre,
    this.iconoUrl,
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
      idCategoria: _intOrNull(json['id_categoria'] ?? json['idCategoria']),
      categoriaNombre: _stringOrNull(json['categoria_nombre'] ?? json['categoriaNombre']),
      iconoUrl: _stringOrNull(json['icono_url'] ?? json['iconoUrl']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_equipo': idEquipo,
      'nombre': nombre,
      'descripcion': descripcion,
      'elo': elo,
      'id_categoria': idCategoria,
      'categoria_nombre': categoriaNombre,
      'icono_url': iconoUrl,
    };
  }
}

class EquipoCreate {
  final String nombre;
  final String? descripcion;
  final int? elo;
  final int idCategoria;
  final int? idUsuario;

  const EquipoCreate({
    required this.nombre,
    required this.idCategoria,
    this.descripcion,
    this.elo,
    this.idUsuario,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'id_categoria': idCategoria,
    if (descripcion != null) 'descripcion': descripcion,
    if (elo != null) 'elo': elo,
    if (idUsuario != null) 'id_usuario': idUsuario,
  };
}

class EquipoUpdate {
  final String? nombre;
  final String? descripcion;
  final int? elo;
  final int? idCategoria;

  const EquipoUpdate({this.nombre, this.descripcion, this.elo, this.idCategoria});

  Map<String, dynamic> toJson() => {
    if (nombre != null) 'nombre': nombre,
    if (descripcion != null) 'descripcion': descripcion,
    if (elo != null) 'elo': elo,
    if (idCategoria != null) 'id_categoria': idCategoria,
  };
}
