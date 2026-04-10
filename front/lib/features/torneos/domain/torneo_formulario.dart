class TorneoFormulario {
  final int idTorneo;
  final String? torneoNombre;
  final Object? formulario;

  const TorneoFormulario({
    required this.idTorneo,
    this.torneoNombre,
    this.formulario,
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

  factory TorneoFormulario.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(json['id_torneo'] ?? json['idTorneo'] ?? json['id']);
    if (id == null) {
      throw const FormatException('TorneoFormulario sin id_torneo');
    }

    return TorneoFormulario(
      idTorneo: id,
      torneoNombre: _stringOrNull(
        json['torneo_nombre'] ?? json['torneoNombre'],
      ),
      formulario: json['formulario'],
    );
  }
}

class UpdateFormularioPayload {
  final Object? formulario;

  const UpdateFormularioPayload({required this.formulario});

  Map<String, dynamic> toJson() => {'formulario': formulario};
}
