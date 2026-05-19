import 'package:front/api/app_torneos_api_client.dart';
import 'package:front/features/categorias/domain/categoria.dart';
import 'package:front/features/torneos/domain/torneo.dart';

class HomeOverview {
  final HomeHero hero;
  final HomeStats stats;
  final List<Categoria> categorias;
  final List<Torneo> torneos;

  const HomeOverview({
    required this.hero,
    required this.stats,
    required this.categorias,
    required this.torneos,
  });

  factory HomeOverview.fromJson(Map<String, dynamic> json) {
    final heroJson = (json['hero'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final statsJson = (json['stats'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    return HomeOverview(
      hero: HomeHero.fromJson(heroJson),
      stats: HomeStats.fromJson(statsJson),
      categorias: (json['categorias'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Categoria.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      torneos: (json['torneos'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Torneo.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }
}

class HomeHero {
  final String title;
  final String subtitle;

  const HomeHero({required this.title, required this.subtitle});

  factory HomeHero.fromJson(Map<String, dynamic> json) {
    return HomeHero(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'Ready for the next challenge?',
      subtitle: (json['subtitle'] as String?)?.trim().isNotEmpty == true
          ? json['subtitle'] as String
          : 'Explora categorías y torneos para entrar en el siguiente reto.',
    );
  }
}

class HomeStats {
  final int totalCategorias;
  final int torneosAbiertos;
  final int torneosEnCurso;
  final int participacionesTotales;

  const HomeStats({
    required this.totalCategorias,
    required this.torneosAbiertos,
    required this.torneosEnCurso,
    required this.participacionesTotales,
  });

  factory HomeStats.fromJson(Map<String, dynamic> json) {
    int readInt(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return HomeStats(
      totalCategorias: readInt('totalCategorias'),
      torneosAbiertos: readInt('torneosAbiertos'),
      torneosEnCurso: readInt('torneosEnCurso'),
      participacionesTotales: readInt('participacionesTotales'),
    );
  }
}

class HomeApi {
  final AppTorneosApiClient _client;

  HomeApi({required String baseUrl}) : _client = AppTorneosApiClient(baseUrl: baseUrl);

  Future<HomeOverview> getHomeOverview({
    int categoriasLimit = 6,
    int torneosLimit = 5,
  }) async {
    final res = await _client.getRaw(
      '/home',
      queryParameters: {
        'categoriasLimit': categoriasLimit.toString(),
        'torneosLimit': torneosLimit.toString(),
      },
    );

    if (res.data is! Map) {
      throw const FormatException('Respuesta inesperada en home');
    }

    return HomeOverview.fromJson(Map<String, dynamic>.from(res.data as Map));
  }
}