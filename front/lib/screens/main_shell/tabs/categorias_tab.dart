import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:front/api/api_exception.dart';
import 'package:front/features/categorias/data/categorias_api.dart';
import 'package:front/features/categorias/domain/categoria.dart';
import 'package:front/features/categorias/widgets/categoria_icon_avatar.dart';
import 'package:front/features/tipos_torneo/domain/tipo_torneo.dart';
import 'package:front/peticion/api_config.dart';

class CategoriasTab extends StatefulWidget {
  const CategoriasTab({super.key});

  @override
  State<CategoriasTab> createState() => _CategoriasTabState();
}

class _CategoriasTabState extends State<CategoriasTab> {
  late final CategoriasApi _categoriasApi = CategoriasApi(baseUrl: ApiConfig.baseUrl);
  late Future<List<Categoria>> _futureCategorias;

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _minParticipantesCtrl = TextEditingController();
  final TextEditingController _maxParticipantesCtrl = TextEditingController();

  String _searchText = '';
  int? _minParticipantes;
  int? _maxParticipantes;

  @override
  void initState() {
    super.initState();
    _futureCategorias = _loadCategorias();

    _searchCtrl.addListener(() {
      final next = _searchCtrl.text;
      if (next == _searchText) return;
      setState(() => _searchText = next);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _minParticipantesCtrl.dispose();
    _maxParticipantesCtrl.dispose();
    super.dispose();
  }

  Future<List<Categoria>> _loadCategorias() async {
    const pageSize = 200;
    final categorias = <Categoria>[];
    var offset = 0;

    while (true) {
      final res = await _categoriasApi.listCategorias(limit: pageSize, offset: offset);
      categorias.addAll(res.data);
      if (res.data.length < pageSize) break;
      offset += pageSize;
    }

    categorias.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return categorias;
  }

  Future<void> _refresh() async {
    setState(() {
      _futureCategorias = _loadCategorias();
    });
    await _futureCategorias;
  }

  List<Categoria> _applyFilters(List<Categoria> input) {
    final search = _searchText.trim().toLowerCase();
    final minP = _minParticipantes;
    final maxP = _maxParticipantes;

    return input.where((cat) {
      if (search.isNotEmpty && !cat.nombre.toLowerCase().contains(search)) {
        return false;
      }
      if (minP != null && cat.participantesPorPartida < minP) return false;
      if (maxP != null && cat.participantesPorPartida > maxP) return false;
      return true;
    }).toList(growable: false);
  }

  void _setMinParticipantes(String raw) {
    final parsed = int.tryParse(raw.trim());
    setState(() => _minParticipantes = parsed);
  }

  void _setMaxParticipantes(String raw) {
    final parsed = int.tryParse(raw.trim());
    setState(() => _maxParticipantes = parsed);
  }

  Future<void> _openCategoriaDetalle(Categoria categoria) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoriaDetalleSheet(categoria: categoria),
    );
  }

  Future<void> _openCrearCategoria() async {
    final created = await showModalBottomSheet<Categoria>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CrearCategoriaSheet(),
    );

    if (!mounted) return;
    if (created == null) return;

    await _refresh();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Categoría "${created.nombre}" creada.')),
    );
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
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
          ],
        ),
      ),
      child: FutureBuilder<List<Categoria>>(
        future: _futureCategorias,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No se pudieron cargar las categorías.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
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

          final categorias = snapshot.data ?? const <Categoria>[];
          final filtered = _applyFilters(categorias);

          final promedioParticipantes = categorias.isEmpty
              ? 0
              : (categorias.fold<int>(0, (sum, c) => sum + c.participantesPorPartida) /
                      categorias.length)
                  .round();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _CategoriasHeaderCard(
                  categoriaCount: categorias.length,
                  promedioParticipantes: promedioParticipantes,
                  onCreate: _openCrearCategoria,
                ),
                const SizedBox(height: 14),
                _FiltrosCard(
                  searchController: _searchCtrl,
                  minParticipantesController: _minParticipantesCtrl,
                  maxParticipantesController: _maxParticipantesCtrl,
                  onMinChanged: _setMinParticipantes,
                  onMaxChanged: _setMaxParticipantes,
                  filteredCount: filtered.length,
                ),
                const SizedBox(height: 14),
                if (categorias.isEmpty)
                  _EmptyState(
                    onCreate: _openCrearCategoria,
                    onRefresh: _refresh,
                  )
                else if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'No hay categorías que coincidan con los filtros.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...filtered.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CategoriaCard(
                        categoria: cat,
                        onTap: () => _openCategoriaDetalle(cat),
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

class _CategoriasHeaderCard extends StatelessWidget {
  const _CategoriasHeaderCard({
    required this.categoriaCount,
    required this.promedioParticipantes,
    required this.onCreate,
  });

  final int categoriaCount;
  final int promedioParticipantes;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF38BDF8),
            Color(0xFF7DD3FC),
            Color(0xFFBAE6FD),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C4A6E).withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.category, color: Colors.white, size: 28),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Categorías',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Explora las categorías existentes y crea nuevas con su icono.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _HeaderStatChip(
                              label: 'Total',
                              value: categoriaCount.toString(),
                            ),
                            const SizedBox(width: 12),
                            _HeaderStatChip(
                              label: 'Promedio participantes',
                              value: promedioParticipantes.toString(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox.expand(
                      child: FilledButton(
                        onPressed: onCreate,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.18),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: Colors.white.withOpacity(0.22)),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 34),
                            SizedBox(height: 6),
                            Text(
                              'Crear',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStatChip extends StatelessWidget {
  const _HeaderStatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltrosCard extends StatelessWidget {
  const _FiltrosCard({
    required this.searchController,
    required this.minParticipantesController,
    required this.maxParticipantesController,
    required this.onMinChanged,
    required this.onMaxChanged,
    required this.filteredCount,
  });

  final TextEditingController searchController;
  final TextEditingController minParticipantesController;
  final TextEditingController maxParticipantesController;
  final ValueChanged<String> onMinChanged;
  final ValueChanged<String> onMaxChanged;
  final int filteredCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filtros',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '$filteredCount resultados',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar por nombre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minParticipantesController,
                  keyboardType: TextInputType.number,
                  onChanged: onMinChanged,
                  decoration: const InputDecoration(
                    labelText: 'Mín participantes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: maxParticipantesController,
                  keyboardType: TextInputType.number,
                  onChanged: onMaxChanged,
                  decoration: const InputDecoration(
                    labelText: 'Máx participantes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate, required this.onRefresh});

  final VoidCallback onCreate;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.category_outlined, size: 40),
          const SizedBox(height: 10),
          const Text('Aún no hay categorías.'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Crear categoría'),
              ),
              OutlinedButton.icon(
                onPressed: () => onRefresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Recargar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  const _CategoriaCard({required this.categoria, required this.onTap});

  final Categoria categoria;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8FCFF), Color(0xFFE8F5FF)],
            ),
            border: Border.all(color: const Color(0xFF7DD3FC).withOpacity(0.28)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0C4A6E).withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoriaIconAvatar(
                  categoria: categoria,
                  baseUrl: ApiConfig.baseUrl,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria.nombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0C4A6E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _Pill(
                            icon: Icons.people_alt,
                            label: '${categoria.participantesPorPartida} por partida',
                          ),
                          _Pill(
                            icon: categoria.tieneIcono ? Icons.image : Icons.image_not_supported,
                            label: categoria.tieneIcono ? 'Con icono' : 'Sin icono',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFBAE6FD).withOpacity(0.28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF0284C7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0284C7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriaDetalleSheet extends StatefulWidget {
  const _CategoriaDetalleSheet({required this.categoria});

  final Categoria categoria;

  @override
  State<_CategoriaDetalleSheet> createState() => _CategoriaDetalleSheetState();
}

class _CategoriaDetalleSheetState extends State<_CategoriaDetalleSheet> {
  late final CategoriasApi _categoriasApi = CategoriasApi(baseUrl: ApiConfig.baseUrl);
  late final Future<List<TipoTorneo>> _futureTipos;

  @override
  void initState() {
    super.initState();
    _futureTipos = _categoriasApi.listTiposTorneoByCategoria(widget.categoria.idCategoria);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoriaIconAvatar(
                    categoria: widget.categoria,
                    baseUrl: ApiConfig.baseUrl,
                    size: 58,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.categoria.nombre,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _DetailChip(
                              label: 'ID',
                              value: widget.categoria.idCategoria.toString(),
                            ),
                            _DetailChip(
                              label: 'Participantes/partida',
                              value: widget.categoria.participantesPorPartida.toString(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Tipos de torneo',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<TipoTorneo>>(
                future: _futureTipos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'No se pudieron cargar los tipos: ${snapshot.error}',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    );
                  }

                  final tipos = snapshot.data ?? const <TipoTorneo>[];
                  if (tipos.isEmpty) {
                    return Text(
                      'Esta categoría no tiene tipos asociados.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  }

                  return Column(
                    children: tipos
                        .map(
                          (t) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.emoji_events_outlined),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.nombre,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (t.descripcion != null &&
                                          t.descripcion!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          t.descripcion!,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CrearCategoriaSheet extends StatefulWidget {
  const _CrearCategoriaSheet();

  @override
  State<_CrearCategoriaSheet> createState() => _CrearCategoriaSheetState();
}

class _CrearCategoriaSheetState extends State<_CrearCategoriaSheet> {
  final _formKey = GlobalKey<FormState>();

  late final CategoriasApi _categoriasApi = CategoriasApi(baseUrl: ApiConfig.baseUrl);

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _participantesCtrl = TextEditingController(text: '2');

  Uint8List? _iconBytes;
  String? _iconName;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _participantesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    if (_loading) return;

    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      setState(() => _error = 'No se pudo leer la imagen seleccionada.');
      return;
    }

    setState(() {
      _iconBytes = file.bytes;
      _iconName = file.name;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) return;

    final participantes = int.tryParse(_participantesCtrl.text.trim()) ?? 0;
    if (participantes <= 0) {
      setState(() => _error = 'Los participantes por partida deben ser > 0.');
      return;
    }

    setState(() => _loading = true);
    try {
      final created = await _categoriasApi.createCategoria(
        CategoriaCreate(
          nombre: _nombreCtrl.text.trim(),
          participantesPorPartida: participantes,
          iconoBytes: _iconBytes,
          iconoNombre: _iconName,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.statusCode == 401 || e.statusCode == 403
            ? 'Debes iniciar sesión para crear categorías.'
            : 'Error creando categoría: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error creando categoría: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.add, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nueva categoría',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Introduce un nombre';
                        if (v.length < 3) return 'Nombre demasiado corto';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _participantesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Participantes por partida',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                backgroundImage:
                                    _iconBytes == null ? null : MemoryImage(_iconBytes!),
                                child: _iconBytes == null
                                    ? const Icon(Icons.category)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Icono',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _iconName ?? 'No seleccionado',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _pickIcon,
                                icon: const Icon(Icons.image),
                                label: const Text('Elegir'),
                              ),
                            ],
                          ),
                          if (_iconBytes != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Tip: si no subes icono, se usará uno por defecto.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: Text(_loading ? 'Creando...' : 'Crear categoría'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
