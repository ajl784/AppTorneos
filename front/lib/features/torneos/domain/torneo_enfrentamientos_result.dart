class TorneoEnfrentamientosResult {
  final bool? ok;
  final String? tipo;

  final int? partidosGenerados;
  final int? rondaGenerada;

  final bool? torneoFinalizado;
  final int? clasificados;
  final int? campeonIdParticipacionEquipo;

  const TorneoEnfrentamientosResult({
    this.ok,
    this.tipo,
    this.partidosGenerados,
    this.rondaGenerada,
    this.torneoFinalizado,
    this.clasificados,
    this.campeonIdParticipacionEquipo,
  });

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _boolOrNull(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  factory TorneoEnfrentamientosResult.fromJson(Map<String, dynamic> json) {
    return TorneoEnfrentamientosResult(
      ok: _boolOrNull(json['ok']),
      tipo: _stringOrNull(json['tipo']),
      partidosGenerados: _intOrNull(
        json['partidosGenerados'] ?? json['partidos_generados'],
      ),
      rondaGenerada: _intOrNull(
        json['rondaGenerada'] ?? json['ronda_generada'],
      ),
      torneoFinalizado: _boolOrNull(
        json['torneoFinalizado'] ?? json['torneo_finalizado'],
      ),
      clasificados: _intOrNull(json['clasificados']),
      campeonIdParticipacionEquipo: _intOrNull(
        json['campeonIdParticipacionEquipo'] ??
            json['campeon_id_participacion_equipo'],
      ),
    );
  }
}
