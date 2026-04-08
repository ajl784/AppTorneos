class Torneo {
  final int id;
  final String nombre;

  const Torneo({
    required this.id,
    required this.nombre,
  });

  factory Torneo.fromJson(Map<String, dynamic> json) {
    return Torneo(
      id: (json['id'] as num).toInt(),
      nombre: (json['nombre'] as String?) ?? '',
    );
  }
}
