class Categoria {
  final int idCategoria;
  final String nombre;
  final int participantesPorPartida;

  const Categoria({
    required this.idCategoria,
    required this.nombre,
    required this.participantesPorPartida,
  });

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory Categoria.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(json['id_categoria'] ?? json['idCategoria']);
    if (id == null) {
      throw const FormatException('Categoria sin id_categoria');
    }

    final participantes =
        _intOrNull(
          json['participantes_por_partida'] ?? json['participantesPorPartida'],
        ) ??
        0;

    return Categoria(
      idCategoria: id,
      nombre: (json['nombre'] as String?) ?? '',
      participantesPorPartida: participantes,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Categoria && other.idCategoria == idCategoria;
  }

  @override
  int get hashCode => idCategoria.hashCode;
}

class CategoriaCreate {
  final String nombre;
  final int participantesPorPartida;

  const CategoriaCreate({
    required this.nombre,
    required this.participantesPorPartida,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'participantes_por_partida': participantesPorPartida,
  };
}
