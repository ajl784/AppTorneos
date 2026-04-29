
import 'package:flutter/material.dart';
import 'package:front/features/equipos/data/equipos_api.dart';
import 'package:front/features/equipos/domain/equipo.dart';
import 'package:front/features/torneos/data/torneos_api.dart';
import 'package:front/features/torneos/domain/torneo_formulario.dart';
import 'package:front/peticion/api_config.dart';
import 'package:front/state/jwt_storage.dart';


class UnirseTorneoScreen extends StatefulWidget {
  final int idTorneo;
  const UnirseTorneoScreen({Key? key, required this.idTorneo}) : super(key: key);

  @override
  State<UnirseTorneoScreen> createState() => _UnirseTorneoScreenState();
}


class _UnirseTorneoScreenState extends State<UnirseTorneoScreen> {
  List<Equipo> _equipos = [];
  int? _equipoSeleccionado;
  TorneoFormulario? _formulario;
  bool _loading = true;
  String? _error;
  final Map<String, dynamic> _respuestas = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Obtener usuario actual
      final user = await JwtStorage.getUser();
      if (user == null || user['id_usuario'] == null) {
        setState(() {
          _error = 'No se pudo obtener el usuario actual';
          _loading = false;
        });
        return;
      }
      final int idUsuario = user['id_usuario'] is int ? user['id_usuario'] : int.tryParse(user['id_usuario'].toString()) ?? 0;
      if (idUsuario == 0) {
        setState(() {
          _error = 'ID de usuario inválido';
          _loading = false;
        });
        return;
      }
      // Obtener equipos
      final equiposApi = EquiposApi(baseUrl: ApiConfig.baseUrl);
      final equiposResp = await equiposApi.getEquiposByUsuario(idUsuario);
      final equipos = equiposResp.data;
      // Obtener formulario
      final torneosApi = TorneosApi(baseUrl: ApiConfig.baseUrl);
      final formulario = await torneosApi.getFormularioTorneo(widget.idTorneo);
      setState(() {
        _equipos = equipos;
        _formulario = formulario;
        _loading = false;
        if (_equipos.isNotEmpty) {
          _equipoSeleccionado = _equipos.first.idEquipo;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Widget _buildFormulario() {
    final form = _formulario?.formulario;
    if (form == null || (form is Map && (form['preguntas'] == null || (form['preguntas'] as List).isEmpty))) {
      return const SizedBox.shrink();
    }
    final preguntas = (form as Map)['preguntas'] as List<dynamic>;
    List<Widget> fields = [];
    for (int i = 0; i < preguntas.length; i++) {
      final pregunta = preguntas[i] as Map<String, dynamic>;
      final tipo = pregunta['tipo'];
      final label = pregunta['label'] ?? 'Pregunta';
      final key = 'q${i + 1}';
      if (tipo == 'texto') {
        fields.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextFormField(
              decoration: InputDecoration(labelText: label),
              onChanged: (v) => _respuestas[key] = v,
            ),
          ),
        );
      } else if (tipo == 'seleccion' && pregunta['opciones'] is List) {
        final opciones = (pregunta['opciones'] as List).cast<String>();
        fields.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: label),
              items: opciones
                  .map((op) => DropdownMenuItem(value: op, child: Text(op)))
                  .toList(),
              onChanged: (v) => _respuestas[key] = v,
            ),
          ),
        );
      }
    }
    return Column(children: fields);
  }

  Future<void> _enviarSolicitud() async {
    if (_equipoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un equipo')));
      return;
    }
    setState(() { _loading = true; });
    try {
      final torneosApi = TorneosApi(baseUrl: ApiConfig.baseUrl);
      final res = await torneosApi.enviarSolicitudUnirse(
        idTorneo: widget.idTorneo,
        idEquipo: _equipoSeleccionado!,
        respuesta: _respuestas.isEmpty ? null : _respuestas,
      );
      setState(() { _loading = false; });
      if (res['id_participacion_equipo'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitud enviada correctamente')));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al enviar la solicitud')));
      }
    } catch (e) {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unirse a Torneo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selecciona tu equipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _equipoSeleccionado,
                        items: _equipos
                            .map((e) => DropdownMenuItem(
                                  value: e.idEquipo,
                                  child: Text(e.nombre),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _equipoSeleccionado = v),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      if (_formulario != null && _formulario!.formulario != null)
                        ...[
                          const Text('Formulario del torneo:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildFormulario(),
                        ],
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('Enviar solicitud'),
                          onPressed: _enviarSolicitud,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
