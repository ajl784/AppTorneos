import 'package:flutter/material.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/features/categorias/widgets/categoria_network_avatar.dart';
import 'package:front/features/torneos/torneos_refresh.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/features/torneos/domain/torneo.dart';
import 'package:front/screens/torneos/torneo_detalle_screen.dart';
import 'package:front/peticion/unirse_torneo.dart';

class TorneosBody extends StatefulWidget {
  const TorneosBody({super.key});

  @override
  State<TorneosBody> createState() => _TorneosBodyState();
}

class _TorneosBodyState extends State<TorneosBody> {
      bool _showFilters = false;

      bool get _hasActiveFilters {
        return (_filterNombre != null && _filterNombre!.isNotEmpty) ||
            (_filterEstado != null && _filterEstado!.isNotEmpty) ||
            (_filterTipo != null && _filterTipo!.isNotEmpty) ||
            (_filterCategoria != null && _filterCategoria!.isNotEmpty) ||
            _filterFechaInicio != null ||
            _filterFechaFin != null;
      }
    // Filtros
    String? _filterNombre;
    String? _filterEstado;
    DateTime? _filterFechaInicio;
    DateTime? _filterFechaFin;
    String? _filterTipo;
    String? _filterCategoria;

    final TextEditingController _nombreController = TextEditingController();

    List<String> _getEstados(List<Torneo> torneos) {
      final estados = torneos.map((t) => t.estado ?? '').where((e) => e.isNotEmpty).toSet().toList();
      estados.sort();
      return estados;
    }
    List<String> _getTipos(List<Torneo> torneos) {
      final tipos = torneos.map((t) => t.tipoTorneoNombre ?? '').where((e) => e.isNotEmpty).toSet().toList();
      tipos.sort();
      return tipos;
    }
    List<String> _getCategorias(List<Torneo> torneos) {
      final cats = torneos.map((t) => t.categoriaNombre ?? '').where((e) => e.isNotEmpty).toSet().toList();
      cats.sort();
      return cats;
    }

    List<Torneo> _applyFilters(List<Torneo> torneos) {
      return torneos.where((t) {
        if (_filterNombre != null && _filterNombre!.isNotEmpty && !(t.nombre.toLowerCase().contains(_filterNombre!.toLowerCase()))) {
          return false;
        }
        if (_filterEstado != null && _filterEstado!.isNotEmpty && (t.estado ?? '') != _filterEstado) {
          return false;
        }
        if (_filterTipo != null && _filterTipo!.isNotEmpty && (t.tipoTorneoNombre ?? '') != _filterTipo) {
          return false;
        }
        if (_filterCategoria != null && _filterCategoria!.isNotEmpty && (t.categoriaNombre ?? '') != _filterCategoria) {
          return false;
        }
        if (_filterFechaInicio != null) {
          final fi = t.fechaInicio != null ? DateTime.tryParse(t.fechaInicio!) : null;
          if (fi == null || fi.isBefore(_filterFechaInicio!)) return false;
        }
        if (_filterFechaFin != null) {
          final ff = t.fechaFin != null ? DateTime.tryParse(t.fechaFin!) : null;
          if (ff == null || ff.isAfter(_filterFechaFin!)) return false;
        }
        return true;
      }).toList();
    }

  @override
  void dispose() {
    TorneosRefresh.instance.tick.removeListener(_refreshListener);
    _nombreController.dispose();
    super.dispose();
  }
  static String _prettyEstado(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
              case 'inscripcion_abierta':
      case 'inscripción_abierta':
        return 'Inscripción abierta';
      case 'inscripcion_terminada':
      case 'inscripción_terminada':
        return 'Inscripción terminada';

      case 'planificado':
        return 'Planificado';
      case 'en_curso':
      case 'en curso':
        return 'En curso';
      case 'acabado':
        return 'Acabado';
      case 'cancelado':
        return 'Cancelado';
      default:
        if (normalized.isEmpty) return '';
        return normalized.replaceFirst(
          normalized[0],
          normalized[0].toUpperCase(),
        );
    }
  }

  static String? _formatDate(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return trimmed;

    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} ${two(parsed.hour)}:${two(parsed.minute)}';
  }

  late final TorneosApi _api = TorneosApi(
    baseUrl: ApiConfig.baseUrl,
  );

  late Future<List<Torneo>> _future;
  late final VoidCallback _refreshListener;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchTorneos();

    _refreshListener = () {
      if (!mounted) return;
      setState(() {
        _future = _api.fetchTorneos();
      });
    };

    TorneosRefresh.instance.tick.addListener(_refreshListener);
  }

  // (Eliminado: método dispose duplicado)

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Torneo>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final torneos = snapshot.data ?? const <Torneo>[];

        if (torneos.isEmpty) {
          return const Center(child: Text('Sin datos'));
        }

        // Filtros disponibles
        final estados = _getEstados(torneos);
        final tipos = _getTipos(torneos);
        final categorias = _getCategorias(torneos);

        final filtered = _applyFilters(torneos);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Torneos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
                        tooltip: _showFilters ? 'Ocultar filtros' : 'Mostrar filtros',
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                      ),
                      if (_hasActiveFilters)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (_showFilters)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          setState(() {
                            _filterNombre = v;
                          });
                        },
                      ),
                    ),
                    DropdownButton<String>(
                      value: _filterEstado != null && estados.contains(_filterEstado) ? _filterEstado : null,
                      hint: const Text('Estado'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Todos')),
                        ...estados.map((e) => DropdownMenuItem(value: e, child: Text(_prettyEstado(e))))
                      ],
                      onChanged: (v) {
                        setState(() {
                          _filterEstado = (v != null && v.isNotEmpty) ? v : null;
                        });
                      },
                    ),
                    DropdownButton<String>(
                      value: _filterTipo != null && tipos.contains(_filterTipo) ? _filterTipo : null,
                      hint: const Text('Tipo'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Todos')),
                        ...tipos.map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      ],
                      onChanged: (v) {
                        setState(() {
                          _filterTipo = (v != null && v.isNotEmpty) ? v : null;
                        });
                      },
                    ),
                    DropdownButton<String>(
                      value: _filterCategoria != null && categorias.contains(_filterCategoria) ? _filterCategoria : null,
                      hint: const Text('Categoría'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Todas')),
                        ...categorias.map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      ],
                      onChanged: (v) {
                        setState(() {
                          _filterCategoria = (v != null && v.isNotEmpty) ? v : null;
                        });
                      },
                    ),
                    // Fecha inicio
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Desde:'),
                        const SizedBox(width: 4),
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _filterFechaInicio ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _filterFechaInicio = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(_filterFechaInicio != null ? '${_filterFechaInicio!.day.toString().padLeft(2, '0')}/${_filterFechaInicio!.month.toString().padLeft(2, '0')}/${_filterFechaInicio!.year}' : 'Cualquiera'),
                          ),
                        ),
                        if (_filterFechaInicio != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _filterFechaInicio = null;
                              });
                            },
                          ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Hasta:'),
                        const SizedBox(width: 4),
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _filterFechaFin ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _filterFechaFin = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(_filterFechaFin != null ? '${_filterFechaFin!.day.toString().padLeft(2, '0')}/${_filterFechaFin!.month.toString().padLeft(2, '0')}/${_filterFechaFin!.year}' : 'Cualquiera'),
                          ),
                        ),
                        if (_filterFechaFin != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _filterFechaFin = null;
                              });
                            },
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear_all),
                      tooltip: 'Limpiar filtros',
                      onPressed: () {
                        setState(() {
                          _nombreController.clear();
                          _filterNombre = null;
                          _filterEstado = null;
                          _filterTipo = null;
                          _filterCategoria = null;
                          _filterFechaInicio = null;
                          _filterFechaFin = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No hay torneos que coincidan con los filtros.'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final colors = Theme.of(context).colorScheme;
                        final cardBg = colors.primary;
                        final onCard = colors.onPrimary;

                        Widget featureBox(String text) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: onCard.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              text,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: cardBg,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          );
                        }

                        final torneo = filtered[index];
                        final hasCategoria = torneo.categoriaId != null;

                        final inicio = _formatDate(torneo.fechaInicio);
                        final fin = _formatDate(torneo.fechaFin);

                        final features = <String>[];

                        if (torneo.estado != null && torneo.estado!.trim().isNotEmpty) {
                          features.add(_prettyEstado(torneo.estado!));
                        }

                        if (inicio != null || fin != null) {
                          if (inicio != null && fin != null) {
                            features.add('$inicio → $fin');
                          } else if (inicio != null) {
                            features.add(inicio);
                          } else if (fin != null) {
                            features.add(fin);
                          }
                        }

                        if (torneo.categoriaNombre != null && torneo.categoriaNombre!.trim().isNotEmpty) {
                          features.add(torneo.categoriaNombre!);
                        }

                        if (torneo.tipoTorneoNombre != null && torneo.tipoTorneoNombre!.trim().isNotEmpty) {
                          features.add(torneo.tipoTorneoNombre!);
                        }

                        final hasDescripcion = torneo.descripcion != null && torneo.descripcion!.trim().isNotEmpty;

                        return Card(
                          color: cardBg,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TorneoDetalleScreen(
                                    torneoId: torneo.id,
                                    torneoNombre: torneo.nombre,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      if (hasCategoria) ...[
                                        CategoriaNetworkAvatar(
                                          categoriaId: torneo.categoriaId!,
                                          baseUrl: ApiConfig.baseUrl,
                                          size: 34,
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      Expanded(
                                        child: Text(
                                          torneo.nombre,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: onCard,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (features.isNotEmpty)
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: features.map(featureBox).toList(growable: false),
                                    ),
                                  if (torneo.estado != null &&
                                      [
                                        'inscripcion_abierta',
                                        'inscripción_abierta'
                                      ].contains(torneo.estado!.trim().toLowerCase()))
                                    ...[
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.login),
                                          label: const Text('Unirse'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: onCard,
                                            foregroundColor: cardBg,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => UnirseTorneoScreen(idTorneo: torneo.id),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  if (hasDescripcion) ...[
                                    if (features.isNotEmpty) const SizedBox(height: 10),
                                    Divider(
                                      color: onCard.withValues(alpha: 0.25),
                                      height: 1,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      torneo.descripcion!,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: onCard.withValues(alpha: 0.85),
                                            height: 1.25,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class TorneosScreenExample extends StatefulWidget {
  const TorneosScreenExample({super.key});

  @override
  State<TorneosScreenExample> createState() => _TorneosScreenExampleState();
}

class _TorneosScreenExampleState extends State<TorneosScreenExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torneos (ejemplo)'),
      ),
      body: const TorneosBody(),
    );
  }
}