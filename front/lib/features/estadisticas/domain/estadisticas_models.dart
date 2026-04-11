class EquipoUsuario {
  final int idEquipo;
  final String nombre;
  final bool esActual;

  const EquipoUsuario({
    required this.idEquipo,
    required this.nombre,
    required this.esActual,
  });

  factory EquipoUsuario.fromJson(Map<String, dynamic> json) {
    final id = json['id_equipo'];
    final nombre = json['nombre'];
    final esActual = json['es_actual'];

    final parsedId = (id is int)
        ? id
        : (id is num)
            ? id.toInt()
            : int.tryParse(id?.toString() ?? '');

    if (parsedId == null) {
      throw const FormatException('EquipoUsuario sin id_equipo');
    }

    return EquipoUsuario(
      idEquipo: parsedId,
      nombre: nombre?.toString() ?? '',
      esActual: esActual == true,
    );
  }
}

class EloPoint {
  final DateTime creadoEn;
  final int eloNuevo;

  const EloPoint({required this.creadoEn, required this.eloNuevo});

  factory EloPoint.fromJson(Map<String, dynamic> json) {
    final creado = json['creado_en']?.toString();
    final elo = json['elo_nuevo'];

    final parsedDate = (creado == null) ? null : DateTime.tryParse(creado);
    final parsedElo = (elo is int)
        ? elo
        : (elo is num)
            ? elo.toInt()
            : int.tryParse(elo?.toString() ?? '');

    if (parsedDate == null || parsedElo == null) {
      throw const FormatException('EloPoint inválido');
    }

    return EloPoint(creadoEn: parsedDate, eloNuevo: parsedElo);
  }
}

class EquipoElo {
  final int idEquipo;
  final String nombre;
  final int eloActual;

  const EquipoElo({
    required this.idEquipo,
    required this.nombre,
    required this.eloActual,
  });

  factory EquipoElo.fromJson(Map<String, dynamic> json) {
    final id = json['id_equipo'];
    final elo = json['elo_actual'];

    final parsedId = (id is int)
        ? id
        : (id is num)
            ? id.toInt()
            : int.tryParse(id?.toString() ?? '');

    final parsedElo = (elo is int)
        ? elo
        : (elo is num)
            ? elo.toInt()
            : int.tryParse(elo?.toString() ?? '');

    if (parsedId == null || parsedElo == null) {
      throw const FormatException('EquipoElo inválido');
    }

    return EquipoElo(
      idEquipo: parsedId,
      nombre: json['nombre']?.toString() ?? '',
      eloActual: parsedElo,
    );
  }
}

class EloHistorialResponse {
  final EquipoElo equipo;
  final List<EloPoint> historial;

  const EloHistorialResponse({required this.equipo, required this.historial});

  factory EloHistorialResponse.fromJson(Map<String, dynamic> json) {
    final equipoRaw = json['equipo'];
    final historialRaw = json['historial'];

    if (equipoRaw is! Map) {
      throw const FormatException('EloHistorialResponse sin equipo');
    }

    final historial = (historialRaw is List)
        ? historialRaw
            .whereType<Map>()
            .map((e) => EloPoint.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : <EloPoint>[];

    return EloHistorialResponse(
      equipo: EquipoElo.fromJson(Map<String, dynamic>.from(equipoRaw)),
      historial: historial,
    );
  }
}

class CategoriaResumen {
  final int idCategoria;
  final String nombre;

  const CategoriaResumen({required this.idCategoria, required this.nombre});

  factory CategoriaResumen.fromJson(Map<String, dynamic> json) {
    final id = json['id_categoria'];
    final parsedId = (id is int)
        ? id
        : (id is num)
            ? id.toInt()
            : int.tryParse(id?.toString() ?? '');

    if (parsedId == null) {
      throw const FormatException('CategoriaResumen sin id_categoria');
    }

    return CategoriaResumen(
      idCategoria: parsedId,
      nombre: json['nombre']?.toString() ?? '',
    );
  }
}

class RankingEntry {
  final int? posicion;
  final int idEquipo;
  final String nombre;
  final int elo;

  const RankingEntry({
    required this.posicion,
    required this.idEquipo,
    required this.nombre,
    required this.elo,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    final pos = json['posicion'];
    final id = json['id_equipo'];
    final elo = json['elo'];

    final parsedPos = (pos == null)
        ? null
        : (pos is int)
            ? pos
            : (pos is num)
                ? pos.toInt()
                : int.tryParse(pos.toString());

    final parsedId = (id is int)
        ? id
        : (id is num)
            ? id.toInt()
            : int.tryParse(id?.toString() ?? '');

    final parsedElo = (elo is int)
        ? elo
        : (elo is num)
            ? elo.toInt()
            : int.tryParse(elo?.toString() ?? '');

    if (parsedId == null || parsedElo == null) {
      throw const FormatException('RankingEntry inválido');
    }

    return RankingEntry(
      posicion: parsedPos,
      idEquipo: parsedId,
      nombre: json['nombre']?.toString() ?? '',
      elo: parsedElo,
    );
  }
}

class RankingResponse {
  final CategoriaResumen? categoria;
  final RankingEntry equipoUsuario;
  final List<RankingEntry> top10;

  const RankingResponse({
    required this.categoria,
    required this.equipoUsuario,
    required this.top10,
  });

  factory RankingResponse.fromJson(Map<String, dynamic> json) {
    final categoriaRaw = json['categoria'];
    final equipoRaw = json['equipo_usuario'];
    final top10Raw = json['top10'];

    if (equipoRaw is! Map) {
      throw const FormatException('RankingResponse sin equipo_usuario');
    }

    final categoria = (categoriaRaw is Map)
        ? CategoriaResumen.fromJson(Map<String, dynamic>.from(categoriaRaw))
        : null;

    final top10 = (top10Raw is List)
        ? top10Raw
            .whereType<Map>()
            .map((e) => RankingEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : <RankingEntry>[];

    return RankingResponse(
      categoria: categoria,
      equipoUsuario: RankingEntry.fromJson(Map<String, dynamic>.from(equipoRaw)),
      top10: top10,
    );
  }
}
