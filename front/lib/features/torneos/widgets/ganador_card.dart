import 'package:flutter/material.dart';
import 'package:front/features/torneos/domain/torneo.dart';
import 'package:front/features/torneos/domain/torneo_clasificacion.dart';
import 'package:front/features/equipos/widgets/equipo_network_avatar.dart';
import 'package:front/peticion/api_config.dart';

class GanadorCard extends StatelessWidget {
  final Torneo torneo;
  final List<TorneoClasificacionItem> clasificacion;

  const GanadorCard({
    super.key,
    required this.torneo,
    required this.clasificacion,
  });

  static String _norm(String value) {
    var v = value.trim().toLowerCase();
    v = v
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ñ', 'n');
    return v;
  }

  bool _isLiga() {
    final tipo = _norm(torneo.tipoTorneoNombre ?? '');
    return tipo == 'liga';
  }

  bool _isEliminacion() {
    final tipo = _norm(torneo.tipoTorneoNombre ?? '');
    return tipo.contains('eliminacion') || tipo.contains('eliminatoria');
  }

  bool _isEliminacionPorSerie() {
    final tipo = _norm(torneo.tipoTorneoNombre ?? '');
    return tipo.contains('serie');
  }

  /// Obtiene el top 3 de la clasificación
  List<TorneoClasificacionItem> _getTop3() {
    return clasificacion.take(3).toList();
  }

  /// Obtiene el campeón (primer lugar)
  TorneoClasificacionItem? _getCampeon() {
    return clasificacion.isNotEmpty ? clasificacion.first : null;
  }

  /// Construye la sección de campeón
  Widget _buildCampeonSection(BuildContext context, TorneoClasificacionItem campeon) {
    final tema = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3), // Tierra clara (paleta ocre/tierra)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFB8860B), // Ocre oscuro
          width: 2,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        children: [
          // Corona/Trofeo simbólico
          const Icon(
            Icons.emoji_events,
            size: 48,
            color: Color(0xFFDAA520), // Goldenrod (oro)
          ),
          const SizedBox(height: 12),
          
          // Título
          Text(
            '¡CAMPEÓN!',
            style: tema.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B4513), // Marrón
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Avatar y nombre del equipo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EquipoNetworkAvatar(
                equipoId: campeon.idEquipo,
                baseUrl: ApiConfig.baseUrl,
                size: 80,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campeon.equipoNombre,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ELO: ${campeon.elo}',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Información según tipo de torneo
          if (_isLiga())
            _buildLigaInfo(context, campeon)
          else if (_isEliminacion() || _isEliminacionPorSerie())
            _buildEliminacionInfo(context, campeon),
        ],
      ),
    );
  }

  /// Información específica para Liga
  Widget _buildLigaInfo(BuildContext context, TorneoClasificacionItem campeon) {
    final tema = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD2B48C)), // Tan
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Puntos',
                    style: tema.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${campeon.puntos}',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B4513),
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              Column(
                children: [
                  Text(
                    'Participantes',
                    style: tema.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${clasificacion.length}',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B4513),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Top 3
        Text(
          'Top 3',
          style: tema.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._getTop3().map((item) => _buildTop3Item(context, item)),
      ],
    );
  }

  /// Widget para cada item del top 3
  Widget _buildTop3Item(BuildContext context, TorneoClasificacionItem item) {
    final tema = Theme.of(context);
    final medallaIcono = item.posicion == 1
        ? '🥇'
        : item.posicion == 2
            ? '🥈'
            : '🥉';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                medallaIcono,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.equipoNombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.puntos} pts',
            style: tema.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B4513),
            ),
          ),
        ],
      ),
    );
  }

  /// Información específica para Eliminación
  Widget _buildEliminacionInfo(BuildContext context, TorneoClasificacionItem campeon) {
    final tema = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD2B48C)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'ELO',
                    style: tema.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${campeon.elo}',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B4513),
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              Column(
                children: [
                  Text(
                    'Participantes',
                    style: tema.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${clasificacion.length}',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B4513),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Clasificación Final',
          style: tema.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._getTop3().map((item) => _buildTop3Item(context, item)).take(3),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final campeon = _getCampeon();
    
    // Si no hay campeón o clasificación vacía, no mostrar nada
    if (campeon == null || clasificacion.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: _buildCampeonSection(context, campeon),
    );
  }
}
