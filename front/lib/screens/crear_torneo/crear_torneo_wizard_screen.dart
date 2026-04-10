import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:front/api/api_exception.dart';
import 'package:front/features/categorias/data/categorias_api.dart';
import 'package:front/features/categorias/domain/categoria.dart';
import 'package:front/features/tipos_torneo/domain/tipo_torneo.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/features/torneos/domain/torneo.dart';

class CrearTorneoWizardScreen extends StatefulWidget {
  const CrearTorneoWizardScreen({super.key});

  @override
  State<CrearTorneoWizardScreen> createState() =>
      _CrearTorneoWizardScreenState();
}

enum _PreguntaTipo { texto, seleccion }

class _PreguntaDraft {
  _PreguntaTipo tipo;
  final TextEditingController label;
  final TextEditingController opcionesCsv;

  _PreguntaDraft({
    required this.tipo,
    String? initialLabel,
    String? initialOpcionesCsv,
  }) : label = TextEditingController(text: initialLabel ?? ''),
       opcionesCsv = TextEditingController(text: initialOpcionesCsv ?? '');

  void dispose() {
    label.dispose();
    opcionesCsv.dispose();
  }

  Map<String, dynamic>? toJsonOrNull() {
    final l = label.text.trim();
    if (l.isEmpty) return null;

    switch (tipo) {
      case _PreguntaTipo.texto:
        return {'tipo': 'texto', 'label': l};
      case _PreguntaTipo.seleccion:
        final opciones = opcionesCsv.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
        return {'tipo': 'seleccion', 'label': l, 'opciones': opciones};
    }
  }
}

class _CrearTorneoWizardScreenState extends State<CrearTorneoWizardScreen> {
  static String _defaultApiBaseUrl() {
    if (kIsWeb) {
      final host = (Uri.base.host.isNotEmpty) ? Uri.base.host : 'localhost';
      return 'http://$host:3000/api/v1';
    }
    return 'http://10.0.2.2:3000/api/v1';
  }

  static const int _totalSteps = 6;

  late final String _baseUrl = _defaultApiBaseUrl();
  late final CategoriasApi _categoriasApi = CategoriasApi(baseUrl: _baseUrl);
  late final TorneosApi _torneosApi = TorneosApi(baseUrl: _baseUrl);

  int _stepIndex = 0;
  bool _loading = false;
  String? _loadError;

  List<Categoria> _categorias = const [];
  Categoria? _categoriaSeleccionada;

  bool _crearCategoriaNueva = false;
  final TextEditingController _nombreTorneoCtrl = TextEditingController();
  final TextEditingController _nombreCategoriaCtrl = TextEditingController();
  final TextEditingController _participantesPorPartidaCtrl =
      TextEditingController(text: '2');

  List<TipoTorneo> _tiposPermitidos = const [];
  String? _modoTipo; // 'liga' | 'eliminacion'
  TipoTorneo? _tipoSeleccionado;

  final TextEditingController _puntosGanarCtrl = TextEditingController(text: '3');
  final TextEditingController _puntosEmpatarCtrl =
      TextEditingController(text: '1');
  final TextEditingController _puntosPerderCtrl =
      TextEditingController(text: '0');
  final TextEditingController _normasExtraCtrl = TextEditingController();

  final TextEditingController _limiteEquiposCtrl = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  final Set<String> _diasSeleccionados = <String>{};

  final List<_PreguntaDraft> _preguntas = <_PreguntaDraft>[
    _PreguntaDraft(tipo: _PreguntaTipo.texto),
  ];

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  @override
  void dispose() {
    _nombreTorneoCtrl.dispose();
    _nombreCategoriaCtrl.dispose();
    _participantesPorPartidaCtrl.dispose();
    _puntosGanarCtrl.dispose();
    _puntosEmpatarCtrl.dispose();
    _puntosPerderCtrl.dispose();
    _normasExtraCtrl.dispose();
    _limiteEquiposCtrl.dispose();

    for (final p in _preguntas) {
      p.dispose();
    }

    super.dispose();
  }

  Future<void> _loadCategorias() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final res = await _categoriasApi.listCategorias(limit: 200, offset: 0);
      if (!mounted) return;
      setState(() {
        _categorias = res.data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onCategoriaChanged(Categoria? value) async {
    setState(() {
      _categoriaSeleccionada = value;
      _tiposPermitidos = const [];
      _modoTipo = null;
      _tipoSeleccionado = null;
    });

    if (value == null) return;

    try {
      final tipos =
          await _categoriasApi.listTiposTorneoByCategoria(value.idCategoria);
      if (!mounted) return;
      setState(() {
        _tiposPermitidos = tipos;
      });

      if (tipos.length == 1) {
        setState(() {
          _tipoSeleccionado = tipos.first;
          _modoTipo = _isLiga(tipos.first) ? 'liga' : 'eliminacion';
        });
      }
    } catch (e) {
      if (!mounted) return;
      _snack('No se pudieron cargar tipos: $e');
    }
  }

  static bool _isLiga(TipoTorneo t) {
    return t.nombre.trim().toLowerCase().contains('liga');
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _formatTime(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';

  static String _formatDateTime(DateTime d) => d.toIso8601String();

  List<String> get _diasSemana => const [
    'lunes',
    'martes',
    'miercoles',
    'jueves',
    'viernes',
    'sabado',
    'domingo',
  ];

  Future<DateTime?> _pickDate(DateTime? current) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay? current) {
    return showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 18, minute: 0),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateStep0() {
    if (_nombreTorneoCtrl.text.trim().isEmpty) {
      _snack('Pon un nombre para el torneo.');
      return false;
    }

    if (_crearCategoriaNueva) {
      if (_nombreCategoriaCtrl.text.trim().isEmpty) {
        _snack('Pon un nombre para la categoría.');
        return false;
      }

      final participantes = int.tryParse(_participantesPorPartidaCtrl.text.trim());
      if (participantes == null || participantes < 2) {
        _snack('Participantes por partida debe ser un número ≥ 2.');
        return false;
      }

      return true;
    }

    if (_categoriaSeleccionada == null) {
      _snack('Selecciona una categoría existente o crea una nueva.');
      return false;
    }

    return true;
  }

  bool _validateStep1() {
    if (_categoriaSeleccionada == null) {
      _snack('Selecciona una categoría primero.');
      return false;
    }

    if (_tipoSeleccionado == null) {
      _snack('Selecciona el tipo de torneo.');
      return false;
    }

    return true;
  }

  bool _validateStep2() {
    final ganar = int.tryParse(_puntosGanarCtrl.text.trim());
    final empatar = int.tryParse(_puntosEmpatarCtrl.text.trim());
    final perder = int.tryParse(_puntosPerderCtrl.text.trim());

    if (ganar == null || empatar == null || perder == null) {
      _snack('Los puntos deben ser números enteros.');
      return false;
    }

    return true;
  }

  bool _validateStep3() {
    final raw = _limiteEquiposCtrl.text.trim();
    if (raw.isEmpty) {
      _snack('Indica el límite de equipos.');
      return false;
    }

    final limite = int.tryParse(raw);
    if (limite == null || limite < 2) {
      _snack('El límite de equipos debe ser un número ≥ 2.');
      return false;
    }

    return true;
  }

  bool _validateStep4() {
    if (_fechaInicio == null) {
      _snack('Selecciona la fecha de inicio.');
      return false;
    }

    if (_fechaFin != null && _fechaFin!.isBefore(_fechaInicio!)) {
      _snack('La fecha de fin no puede ser anterior al inicio.');
      return false;
    }

    if (_diasSeleccionados.isEmpty) {
      _snack('Selecciona al menos un día para jugar.');
      return false;
    }

    return true;
  }

  bool _validateStep5() {
    final hasAny = _preguntas
        .map((p) => p.toJsonOrNull())
        .whereType<Map<String, dynamic>>()
        .isNotEmpty;

    if (!hasAny) {
      _snack('Añade al menos una pregunta al formulario.');
      return false;
    }

    return true;
  }

  String _buildNormaPuntuacion() {
    final ganar = int.tryParse(_puntosGanarCtrl.text.trim()) ?? 0;
    final empatar = int.tryParse(_puntosEmpatarCtrl.text.trim()) ?? 0;
    final perder = int.tryParse(_puntosPerderCtrl.text.trim()) ?? 0;

    final base = 'victoria=$ganar;empate=$empatar;derrota=$perder';
    final extra = _normasExtraCtrl.text.trim();
    return extra.isEmpty ? base : '$base;$extra';
  }

  Map<String, dynamic>? _buildPreferenciaHorario() {
    if (_diasSeleccionados.isEmpty && _horaInicio == null && _horaFin == null) {
      return null;
    }

    final map = <String, dynamic>{
      if (_diasSeleccionados.isNotEmpty) 'dias': _diasSeleccionados.toList(),
      if (_horaInicio != null) 'hora_inicio': _formatTime(_horaInicio!),
      if (_horaFin != null) 'hora_fin': _formatTime(_horaFin!),
    };

    return map.isEmpty ? null : map;
  }

  Object? _buildEncuesta() {
    final preguntas = _preguntas
        .map((p) => p.toJsonOrNull())
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    return {'preguntas': preguntas};
  }

  void _handleBack() {
    if (_loading) return;
    if (_stepIndex == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _stepIndex -= 1);
  }

  Future<void> _handleNext() async {
    if (_loading) return;

    if (_stepIndex == 0) {
      if (!_validateStep0()) return;

      if (_crearCategoriaNueva) {
        final nombreCat = _nombreCategoriaCtrl.text.trim();
        final participantes =
            int.tryParse(_participantesPorPartidaCtrl.text.trim()) ?? 2;

        setState(() => _loading = true);
        try {
          final created = await _categoriasApi.createCategoria(
            CategoriaCreate(
              nombre: nombreCat,
              participantesPorPartida: participantes,
            ),
          );

          if (!mounted) return;

          await _loadCategorias();
          if (!mounted) return;

          setState(() {
            _crearCategoriaNueva = false;
            _categoriaSeleccionada = created;
            _loading = false;
          });

          await _onCategoriaChanged(created);
        } catch (e) {
          if (!mounted) return;
          setState(() => _loading = false);
          _snack('Error creando categoría: $e');
          return;
        }
      }

      setState(() => _stepIndex = 1);
      return;
    }

    if (_stepIndex == 1) {
      if (!_validateStep1()) return;
      setState(() => _stepIndex = 2);
      return;
    }

    if (_stepIndex == 2) {
      if (!_validateStep2()) return;
      setState(() => _stepIndex = 3);
      return;
    }

    if (_stepIndex == 3) {
      if (!_validateStep3()) return;
      setState(() => _stepIndex = 4);
      return;
    }

    if (_stepIndex == 4) {
      if (!_validateStep4()) return;
      setState(() => _stepIndex = 5);
      return;
    }

    if (!_validateStep5()) return;

    final categoria = _categoriaSeleccionada;
    final tipo = _tipoSeleccionado;
    if (categoria == null || tipo == null) {
      _snack('Faltan datos (categoría/tipo).');
      return;
    }

    final limite = int.tryParse(_limiteEquiposCtrl.text.trim());

    final payload = TorneoCreate(
      nombre: _nombreTorneoCtrl.text.trim(),
      idCategoria: categoria.idCategoria,
      idTipoTorneo: tipo.idTipoTorneo,
      limiteEquipos: limite,
      fechaInicio: _fechaInicio == null ? null : _formatDateTime(_fechaInicio!),
      fechaFin: _fechaFin == null ? null : _formatDateTime(_fechaFin!),
      normaPuntuacion: _buildNormaPuntuacion(),
      preferenciaHorario: _buildPreferenciaHorario(),
      encuesta: _buildEncuesta(),
    );

    setState(() => _loading = true);
    try {
      final created = await _torneosApi.createTorneo(payload);
      if (!mounted) return;

      setState(() => _loading = false);
      _snack('Torneo creado: ${created.nombre}');
      Navigator.of(context).pop(created);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Error API (${e.statusCode}): ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Error creando torneo: $e');
    }
  }

  Widget _stepsHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget stepCircle(int idx) {
      final isCurrent = idx == _stepIndex;
      final isDone = idx < _stepIndex;

      final bg = isCurrent
          ? colors.primary
          : isDone
              ? colors.primaryContainer
              : colors.surfaceVariant;
      final fg = isCurrent
          ? colors.onPrimary
          : isDone
              ? colors.onPrimaryContainer
              : colors.onSurfaceVariant;

      return InkWell(
        customBorder: const CircleBorder(),
        onTap: _loading ? null : () => setState(() => _stepIndex = idx),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? colors.primary : colors.outlineVariant,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '${idx + 1}',
            style: TextStyle(color: fg, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    Widget arrow() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: colors.onSurfaceVariant,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < _totalSteps; i++) ...[
            stepCircle(i),
            if (i != _totalSteps - 1) arrow(),
          ],
        ],
      ),
    );
  }

  Widget _stepForIndex(BuildContext context) {
    switch (_stepIndex) {
      case 0:
        return _stepNombreCategoria(context);
      case 1:
        return _stepTipo(context);
      case 2:
        return _stepPuntos(context);
      case 3:
        return _stepLimite(context);
      case 4:
        return _stepFechasHorario(context);
      default:
        return _stepFormulario(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _categorias.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crear torneo')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crear torneo')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error: $_loadError'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadCategorias,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final stepContent = _stepForIndex(context);
    final isLast = _stepIndex == _totalSteps - 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear torneo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _stepsHeader(context),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: stepContent,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleBack,
                      child: Text(_stepIndex == 0 ? 'Cancelar' : 'Atrás'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _loading ? null : _handleNext,
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isLast ? 'Crear torneo' : 'Siguiente'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepNombreCategoria(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nombreTorneoCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre del torneo',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _crearCategoriaNueva,
          onChanged: (v) {
            setState(() {
              _crearCategoriaNueva = v ?? false;
              if (_crearCategoriaNueva) {
                _categoriaSeleccionada = null;
                _tiposPermitidos = const [];
                _modoTipo = null;
                _tipoSeleccionado = null;
              }
            });
          },
          title: const Text('Crear nueva categoría'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        if (_crearCategoriaNueva) ...[
          TextField(
            controller: _nombreCategoriaCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre de la categoría',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _participantesPorPartidaCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Participantes por partida',
              helperText: 'Ej: 2 (duelos), 4 (Parchís), 8 (Atletismo)',
              border: OutlineInputBorder(),
            ),
          ),
        ] else ...[
          DropdownButtonFormField<Categoria>(
            value: _categoriaSeleccionada,
            items: _categorias
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.nombre} (${c.participantesPorPartida})'),
                  ),
                )
                .toList(growable: false),
            onChanged: _onCategoriaChanged,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _stepTipo(BuildContext context) {
    if (_categoriaSeleccionada == null) {
      return const Text('Selecciona una categoría en el paso 1.');
    }

    if (_tiposPermitidos.isEmpty) {
      return const Text('Cargando tipos permitidos para la categoría...');
    }

    final ligas = _tiposPermitidos.where(_isLiga).toList(growable: false);
    final eliminaciones =
        _tiposPermitidos.where((t) => !_isLiga(t)).toList(growable: false);

    final ligaEnabled = ligas.isNotEmpty;
    final elimEnabled = eliminaciones.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Elige el tipo de torneo:'),
        const SizedBox(height: 8),
        RadioListTile<String>(
          value: 'liga',
          groupValue: _modoTipo,
          onChanged: ligaEnabled
              ? (v) {
                  setState(() {
                    _modoTipo = v;
                    _tipoSeleccionado = ligas.isNotEmpty ? ligas.first : null;
                  });
                }
              : null,
          title: const Text('Liga'),
          subtitle: ligaEnabled
              ? null
              : const Text('No disponible en esta categoría'),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          value: 'eliminacion',
          groupValue: _modoTipo,
          onChanged: elimEnabled
              ? (v) {
                  setState(() {
                    _modoTipo = v;
                    _tipoSeleccionado = null;
                  });
                }
              : null,
          title: const Text('Eliminación'),
          subtitle: elimEnabled
              ? null
              : const Text('No disponible en esta categoría'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        if (_modoTipo == 'eliminacion')
          DropdownButtonFormField<TipoTorneo>(
            value: _tipoSeleccionado,
            items: eliminaciones
                .map((t) => DropdownMenuItem(value: t, child: Text(t.nombre)))
                .toList(growable: false),
            onChanged: (t) => setState(() => _tipoSeleccionado = t),
            decoration: const InputDecoration(
              labelText: 'Variante de eliminación',
              border: OutlineInputBorder(),
            ),
          ),
        if (_modoTipo == 'liga')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Tipo seleccionado: ${_tipoSeleccionado?.nombre ?? 'Liga'}',
            ),
          ),
      ],
    );
  }

  Widget _stepPuntos(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Configura los puntos y normas:'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _puntosGanarCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ganar',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _puntosEmpatarCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Empatar',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _puntosPerderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Perder',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _normasExtraCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Normas adicionales (opcional)',
            helperText: 'Formato libre. Ej: criterio=asc;finalistas=8',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _stepLimite(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _limiteEquiposCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Límite de equipos del torneo',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _stepFechasHorario(BuildContext context) {
    String? prettyDate(DateTime? d) {
      if (d == null) return null;
      return '${_two(d.day)}/${_two(d.month)}/${d.year}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final picked = await _pickDate(_fechaInicio);
                  if (picked == null) return;
                  setState(() => _fechaInicio = picked);
                },
                child: Text(
                  _fechaInicio == null
                      ? 'Fecha inicio'
                      : 'Inicio: ${prettyDate(_fechaInicio)}',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final picked = await _pickDate(_fechaFin);
                  if (picked == null) return;
                  setState(() => _fechaFin = picked);
                },
                child: Text(
                  _fechaFin == null
                      ? 'Fecha fin (opcional)'
                      : 'Fin: ${prettyDate(_fechaFin)}',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final picked = await _pickTime(_horaInicio);
                  if (picked == null) return;
                  setState(() => _horaInicio = picked);
                },
                child: Text(
                  _horaInicio == null
                      ? 'Hora inicio (opcional)'
                      : 'Hora inicio: ${_formatTime(_horaInicio!)}',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final picked = await _pickTime(_horaFin);
                  if (picked == null) return;
                  setState(() => _horaFin = picked);
                },
                child: Text(
                  _horaFin == null
                      ? 'Hora fin (opcional)'
                      : 'Hora fin: ${_formatTime(_horaFin!)}',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Días de juego:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _diasSemana
              .map(
                (d) => FilterChip(
                  label: Text(d),
                  selected: _diasSeleccionados.contains(d),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _diasSeleccionados.add(d);
                      } else {
                        _diasSeleccionados.remove(d);
                      }
                    });
                  },
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _stepFormulario(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Crea el formulario del torneo:'),
        const SizedBox(height: 12),
        ..._preguntas.asMap().entries.map((entry) {
          final idx = entry.key;
          final p = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Pregunta ${idx + 1}'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<_PreguntaTipo>(
                      value: p.tipo,
                      items: const [
                        DropdownMenuItem(
                          value: _PreguntaTipo.texto,
                          child: Text('Respuesta escrita'),
                        ),
                        DropdownMenuItem(
                          value: _PreguntaTipo.seleccion,
                          child: Text('Selección'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => p.tipo = v);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: p.label,
                      decoration: const InputDecoration(
                        labelText: 'Texto de la pregunta',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (p.tipo == _PreguntaTipo.seleccion) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: p.opcionesCsv,
                        decoration: const InputDecoration(
                          labelText: 'Opciones (separadas por coma)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _preguntas.add(_PreguntaDraft(tipo: _PreguntaTipo.texto));
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Añadir pregunta'),
        ),
      ],
    );
  }
}
