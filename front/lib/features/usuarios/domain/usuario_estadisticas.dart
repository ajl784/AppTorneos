class UsuarioEloResumen {
  final int idUsuario;
  final String? correo;
  final String? nombreUsuario;
  final List<EquipoEloResumen> equipos;

  const UsuarioEloResumen({
    required this.idUsuario,
    required this.correo,
    required this.nombreUsuario,
    required this.equipos,
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

  factory UsuarioEloResumen.fromJson(Map<String, dynamic> json) {
    final usuario = (json['usuario'] is Map<String, dynamic>)
        ? json['usuario'] as Map<String, dynamic>
        : <String, dynamic>{};

    final id = _intOrNull(
      usuario['id_usuario'] ?? usuario['idUsuario'] ?? usuario['id'],
    );

    if (id == null) {
      throw const FormatException('UsuarioEloResumen sin id_usuario');
    }

    final equiposRaw = json['equipos'];
    final equipos = (equiposRaw is List)
        ? equiposRaw
              .whereType<Map>()
              .map(
                (e) => EquipoEloResumen.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
        : <EquipoEloResumen>[];

    return UsuarioEloResumen(
      idUsuario: id,
      correo: _stringOrNull(usuario['correo']),
      nombreUsuario: _stringOrNull(usuario['nombre_usuario']),
      equipos: equipos,
    );
  }
}

class EquipoEloResumen {
  final int idEquipo;
  final String nombre;
  final String? descripcion;
  final int eloActual;
  final CategoriaEquipo? categoria;
  final List<HistorialEloItem> historialElo;
  final RankingCategoria rankingCategoria;

  const EquipoEloResumen({
    required this.idEquipo,
    required this.nombre,
    required this.descripcion,
    required this.eloActual,
    required this.categoria,
    required this.historialElo,
    required this.rankingCategoria,
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

  factory EquipoEloResumen.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(json['id_equipo'] ?? json['idEquipo'] ?? json['id']);
    if (id == null) {
      throw const FormatException('EquipoEloResumen sin id_equipo');
    }

    final elo = _intOrNull(json['elo_actual'] ?? json['eloActual']) ?? 0;

    final categoriaRaw = json['categoria'];
    final categoria = (categoriaRaw is Map)
        ? CategoriaEquipo.fromJson(Map<String, dynamic>.from(categoriaRaw))
        : null;

    final historialRaw = json['historial_elo'];
    final historial = (historialRaw is List)
        ? historialRaw
              .whereType<Map>()
              .map(
                (item) =>
                    HistorialEloItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
        : <HistorialEloItem>[];

    final rankingRaw = json['ranking_categoria'];
    final ranking = (rankingRaw is Map)
        ? RankingCategoria.fromJson(Map<String, dynamic>.from(rankingRaw))
        : const RankingCategoria.empty();

    return EquipoEloResumen(
      idEquipo: id,
      nombre: _stringOrNull(json['nombre']) ?? '',
      descripcion: _stringOrNull(json['descripcion']),
      eloActual: elo,
      categoria: categoria,
      historialElo: historial,
      rankingCategoria: ranking,
    );
  }
}

class CategoriaEquipo {
  final int idCategoria;
  final String nombre;

  const CategoriaEquipo({required this.idCategoria, required this.nombre});

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory CategoriaEquipo.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(
      json['id_categoria'] ?? json['idCategoria'] ?? json['id'],
    );

    if (id == null) {
      throw const FormatException('CategoriaEquipo sin id_categoria');
    }

    return CategoriaEquipo(idCategoria: id, nombre: json['nombre']?.toString() ?? '');
  }
}

class HistorialEloItem {
  final int idHistorial;
  final int eloAnterior;
  final int eloNuevo;
  final String? descripcion;
  final DateTime? creadoEn;

  const HistorialEloItem({
    required this.idHistorial,
    required this.eloAnterior,
    required this.eloNuevo,
    required this.descripcion,
    required this.creadoEn,
  });

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _dateOrNull(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory HistorialEloItem.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(
      json['id_historial_elo'] ?? json['idHistorialElo'] ?? json['id'],
    );
    if (id == null) {
      throw const FormatException('HistorialEloItem sin id_historial_elo');
    }

    return HistorialEloItem(
      idHistorial: id,
      eloAnterior: _intOrNull(json['elo_anterior']) ?? 0,
      eloNuevo: _intOrNull(json['elo_nuevo']) ?? 0,
      descripcion: json['descripcion']?.toString(),
      creadoEn: _dateOrNull(json['creado_en']),
    );
  }
}

class RankingCategoria {
  final List<RankingEquipoItem> top10;
  final int? posicionEquipoUsuario;
  final int totalEquipos;
  final RankingEquipoItem? equipoUsuario;

  const RankingCategoria({
    required this.top10,
    required this.posicionEquipoUsuario,
    required this.totalEquipos,
    required this.equipoUsuario,
  });

  const RankingCategoria.empty()
    : top10 = const [],
      posicionEquipoUsuario = null,
      totalEquipos = 0,
      equipoUsuario = null;

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory RankingCategoria.fromJson(Map<String, dynamic> json) {
    final topRaw = json['top_10'];
    final top = (topRaw is List)
        ? topRaw
              .whereType<Map>()
              .map((item) => RankingEquipoItem.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false)
        : <RankingEquipoItem>[];

    final equipoUsuarioRaw = json['equipo_usuario'];
    final equipoUsuario = (equipoUsuarioRaw is Map)
        ? RankingEquipoItem.fromJson(Map<String, dynamic>.from(equipoUsuarioRaw))
        : null;

    return RankingCategoria(
      top10: top,
      posicionEquipoUsuario: _intOrNull(json['posicion_equipo_usuario']),
      totalEquipos: _intOrNull(json['total_equipos']) ?? top.length,
      equipoUsuario: equipoUsuario,
    );
  }
}

class RankingEquipoItem {
  final int idEquipo;
  final String nombre;
  final int elo;
  final int posicion;
  final bool esEquipoUsuario;

  const RankingEquipoItem({
    required this.idEquipo,
    required this.nombre,
    required this.elo,
    required this.posicion,
    required this.esEquipoUsuario,
  });

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _boolOrFalse(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1';
    }
    return false;
  }

  factory RankingEquipoItem.fromJson(Map<String, dynamic> json) {
    final id = _intOrNull(json['id_equipo'] ?? json['idEquipo'] ?? json['id']);
    if (id == null) {
      throw const FormatException('RankingEquipoItem sin id_equipo');
    }

    return RankingEquipoItem(
      idEquipo: id,
      nombre: json['nombre']?.toString() ?? '',
      elo: _intOrNull(json['elo']) ?? 0,
      posicion: _intOrNull(json['posicion']) ?? 0,
      esEquipoUsuario: _boolOrFalse(json['es_equipo_usuario'] ?? json['esEquipoUsuario']),
    );
  }
}