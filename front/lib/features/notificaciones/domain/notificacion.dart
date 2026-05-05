class Notificacion {
  final String idNotificacion;
  final String idUsuarioDestino;
  final String tipo;
  final String titulo;
  final String mensaje;
  final Map<String, dynamic> datos;
  final bool leida;
  final DateTime fechaCreacion;
  final DateTime? fechaLeida;

  Notificacion({
    required this.idNotificacion,
    required this.idUsuarioDestino,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.datos,
    required this.leida,
    required this.fechaCreacion,
    this.fechaLeida,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      idNotificacion: json['id_notificacion'].toString(),
      idUsuarioDestino: json['id_usuario_destino'].toString(),
      tipo: json['tipo'] as String,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      datos: json['datos'] as Map<String, dynamic>? ?? {},
      leida: json['leida'] as bool,
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      fechaLeida: json['fecha_leida'] != null
          ? DateTime.parse(json['fecha_leida'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_notificacion': idNotificacion,
      'id_usuario_destino': idUsuarioDestino,
      'tipo': tipo,
      'titulo': titulo,
      'mensaje': mensaje,
      'datos': datos,
      'leida': leida,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_leida': fechaLeida?.toIso8601String(),
    };
  }


  Notificacion copyWith({
    String? idNotificacion,
    String? idUsuarioDestino,
    String? tipo,
    String? titulo,
    String? mensaje,
    Map<String, dynamic>? datos,
    bool? leida,
    DateTime? fechaCreacion,
    DateTime? fechaLeida,
  }) {
    return Notificacion(
      idNotificacion: idNotificacion ?? this.idNotificacion,
      idUsuarioDestino: idUsuarioDestino ?? this.idUsuarioDestino,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      datos: datos ?? this.datos,
      leida: leida ?? this.leida,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaLeida: fechaLeida ?? this.fechaLeida,
    );
  }

}