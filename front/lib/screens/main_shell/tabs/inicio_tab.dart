import 'package:flutter/material.dart';

import 'package:front/api/api_exception.dart';
import 'package:front/features/categorias/domain/categoria.dart';
import 'package:front/features/categorias/widgets/categoria_icon_avatar.dart';
import 'package:front/features/home/data/home_api.dart';
import 'package:front/features/torneos/domain/torneo.dart';
import 'package:front/peticion/api_config.dart';

class InicioTab extends StatefulWidget {
  const InicioTab({
    super.key,
    this.onJoinTournament,
    this.onCreateTournament,
    this.onBrowseCategories,
  });

  final VoidCallback? onJoinTournament;
  final VoidCallback? onCreateTournament;
  final VoidCallback? onBrowseCategories;

  @override
  State<InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<InicioTab> {
  late final HomeApi _homeApi = HomeApi(baseUrl: ApiConfig.baseUrl);
  late Future<HomeOverview> _futureHome;

  @override
  void initState() {
    super.initState();
    _futureHome = _loadHome();
  }

  Future<HomeOverview> _loadHome() {
    return _homeApi.getHomeOverview();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureHome = _loadHome();
    });
    await _futureHome;
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Próximamente';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface,
            const Color(0xFFF0F7FF),
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
          ],
        ),
      ),
      child: FutureBuilder<HomeOverview>(
        future: _futureHome,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No se pudo cargar la pantalla de inicio.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error is ApiException
                          ? (snapshot.error as ApiException).message
                          : snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final home = snapshot.data;
          if (home == null) {
            return const SizedBox.shrink();
          }

          final featuredCategorias = home.categorias;
          final upcomingTorneos = home.torneos;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _HomeHeroCard(
                  hero: home.hero,
                  stats: home.stats,
                  featuredCategorias: featuredCategorias,
                  onJoinTournament: widget.onJoinTournament,
                  onCreateTournament: widget.onCreateTournament,
                ),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: 'Categorías destacadas',
                  subtitle: 'Una selección aleatoria para que siempre veas algo distinto.',
                  onAction: widget.onBrowseCategories,
                  actionLabel: 'Ver todas',
                ),
                const SizedBox(height: 12),
                if (featuredCategorias.isEmpty)
                  _EmptyInlineCard(
                    message: 'Todavía no hay categorías publicadas.',
                    icon: Icons.category_outlined,
                    actionLabel: 'Crear torneo',
                    onAction: widget.onCreateTournament,
                  )
                else
                  SizedBox(
                    height: 178,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: featuredCategorias.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final categoria = featuredCategorias[index];
                        return _CategoryShowcaseCard(
                          categoria: categoria,
                          onTap: widget.onBrowseCategories,
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Próximos torneos',
                  subtitle: 'Eventos listos para entrar con cupo y participantes visibles.',
                  onAction: widget.onJoinTournament,
                  actionLabel: 'Explorar torneos',
                ),
                const SizedBox(height: 12),
                if (upcomingTorneos.isEmpty)
                  _EmptyInlineCard(
                    message: 'Aún no hay torneos próximos para mostrar.',
                    icon: Icons.emoji_events_outlined,
                    actionLabel: 'Crear torneo',
                    onAction: widget.onCreateTournament,
                  )
                else
                  ...upcomingTorneos.map(
                    (torneo) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _TournamentCard(
                        torneo: torneo,
                        onTap: widget.onJoinTournament,
                        formatDate: _formatDate,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({
    required this.hero,
    required this.stats,
    required this.featuredCategorias,
    required this.onJoinTournament,
    required this.onCreateTournament,
  });

  final HomeHero hero;
  final HomeStats stats;
  final List<Categoria> featuredCategorias;
  final VoidCallback? onJoinTournament;
  final VoidCallback? onCreateTournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF052E3D),
            Color(0xFF0F5A75),
            Color(0xFF4BC2D7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1E29).withOpacity(0.28),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -28,
            child: _GlowOrb(color: accent.withOpacity(0.22), size: 160),
          ),
          Positioned(
            left: -36,
            bottom: -44,
            child: _GlowOrb(color: Colors.white.withOpacity(0.08), size: 140),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withOpacity(0.16)),
                          ),
                          child: const Text(
                            'Torneos vivos · comunidad activa',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hero.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 0.96,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hero.subtitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.86),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  _AvatarCluster(categorias: featuredCategorias),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _HeroStatPill(label: 'Categorías', value: stats.totalCategorias.toString()),
                  _HeroStatPill(label: 'Abiertos', value: stats.torneosAbiertos.toString()),
                  _HeroStatPill(label: 'En curso', value: stats.torneosEnCurso.toString()),
                  _HeroStatPill(label: 'Inscritos', value: stats.participacionesTotales.toString()),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onJoinTournament,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F5A75),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Unirse a Torneo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCreateTournament,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Crear Torneo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarCluster extends StatelessWidget {
  const _AvatarCluster({required this.categorias});

  final List<Categoria> categorias;

  @override
  Widget build(BuildContext context) {
    final baseUrl = ApiConfig.baseUrl;
    final visible = categorias.take(3).toList(growable: false);

    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 6,
            top: 28,
            child: _FloatingTile(label: 'LIVE', value: '24'),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: _FloatingTile(label: 'RANK', value: 'A+'),
          ),
          if (visible.isNotEmpty)
            Positioned(
              left: 8,
              bottom: 6,
              child: _MiniAvatar(
                categoria: visible.first,
                baseUrl: baseUrl,
              ),
            ),
          if (visible.length > 1)
            Positioned(
              right: 10,
              bottom: 8,
              child: _MiniAvatar(
                categoria: visible[1],
                baseUrl: baseUrl,
              ),
            ),
          if (visible.length > 2)
            Positioned(
              left: 42,
              top: 42,
              child: _MiniAvatar(
                categoria: visible[2],
                baseUrl: baseUrl,
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.categoria, required this.baseUrl});

  final Categoria categoria;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.75), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CategoriaIconAvatar(
        categoria: categoria,
        baseUrl: baseUrl,
        size: 42,
      ),
    );
  }
}

class _FloatingTile extends StatelessWidget {
  const _FloatingTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.84),
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  const _HeroStatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _CategoryShowcaseCard extends StatelessWidget {
  const _CategoryShowcaseCard({required this.categoria, required this.onTap});

  final Categoria categoria;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final baseUrl = ApiConfig.baseUrl;

    return SizedBox(
      width: 180,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CategoriaIconAvatar(
                    categoria: categoria,
                    baseUrl: baseUrl,
                    size: 52,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${categoria.participantesPorPartida}v',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                categoria.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                categoria.descripcion?.trim().isNotEmpty == true
                    ? categoria.descripcion!
                    : 'Visual card para descubrir partidas, equipos y torneos activos.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({
    required this.torneo,
    required this.onTap,
    required this.formatDate,
  });

  final Torneo torneo;
  final VoidCallback? onTap;
  final String Function(String? raw) formatDate;

  String _participantsLabel() {
    final actual = torneo.participantesActuales ?? 0;
    final max = torneo.limiteEquipos;
    if (max == null || max <= 0) {
      return '$actual inscritos';
    }
    return '$actual / $max';
  }

  double _progressValue() {
    final actual = torneo.participantesActuales ?? 0;
    final max = torneo.limiteEquipos;
    if (max == null || max <= 0) {
      return 0.0;
    }
    return (actual / max).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final participants = _participantsLabel();
    final progress = _progressValue();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        torneo.nombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        torneo.descripcion?.trim().isNotEmpty == true
                            ? torneo.descripcion!
                            : 'Evento moderno listo para captar participantes y seguir su progreso.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: theme.colorScheme.primaryContainer,
                  ),
                  child: Text(
                    torneo.estado?.replaceAll('_', ' ').toUpperCase() ?? 'ABIERTO',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    label: 'Inicio',
                    value: formatDate(torneo.fechaInicio),
                    icon: Icons.schedule,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoChip(
                    label: 'Participantes',
                    value: participants,
                    icon: Icons.groups_2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: progress,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInlineCard extends StatelessWidget {
  const _EmptyInlineCard({
    required this.message,
    required this.icon,
    required this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2EEF6)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF0F5A75)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}