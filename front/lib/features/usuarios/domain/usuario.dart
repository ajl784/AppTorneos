class Usuario {
  final int idUsuario;
  final String correo;
  final String nombreUsuario;

  const Usuario({
    required this.idUsuario,
    required this.correo,
    required this.nombreUsuario,
  });

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(
      json['id_usuario'] ?? json['idUsuario'] ?? json['id'],
    );
    if (id == null) {
      throw const FormatException('Usuario sin id_usuario');
    }

    return Usuario(
      idUsuario: id,
      correo: (json['correo'] as String?) ?? '',
      nombreUsuario:
          (json['nombre_usuario'] as String?) ??
          (json['nombreUsuario'] as String?) ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'correo': correo,
      'nombre_usuario': nombreUsuario,
    };
  }
}

class UsuarioCreate {
  final String correo;
  final String nombreUsuario;
  final String password;

  const UsuarioCreate({
    required this.correo,
    required this.nombreUsuario,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'correo': correo,
    'nombre_usuario': nombreUsuario,
    'password': password,
  };
}

class UsuarioUpdate {
  final String? correo;
  final String? nombreUsuario;
  final String? password;

  const UsuarioUpdate({this.correo, this.nombreUsuario, this.password});

  Map<String, dynamic> toJson() => {
    if (correo != null) 'correo': correo,
    if (nombreUsuario != null) 'nombre_usuario': nombreUsuario,
    if (password != null) 'password': password,
  };
}
