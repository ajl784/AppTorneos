
import 'package:flutter/material.dart';
import 'package:front/api/app_torneos_api_client.dart';
import 'package:front/features/usuarios/data/usuarios_api.dart';
import 'package:front/state/jwt_storage.dart';


class GestionArbitrosTorneoScreen extends StatefulWidget {
  final String torneoNombre;
  final int torneoId;

  const GestionArbitrosTorneoScreen({
    Key? key,
    required this.torneoNombre,
    required this.torneoId,
  }) : super(key: key);

  @override
  State<GestionArbitrosTorneoScreen> createState() => _GestionArbitrosTorneoScreenState();
}

class _GestionArbitrosTorneoScreenState extends State<GestionArbitrosTorneoScreen> {
  final TextEditingController _arbitroController = TextEditingController();
  bool _loading = false;

  Future<void> _invitarArbitro(BuildContext context) async {
    final input = _arbitroController.text.trim();
    if (input.isEmpty) return;
    setState(() => _loading = true);
    try {
      // Usa la URL base directamente (ajusta si tu backend cambia de puerto o ruta)
      const baseUrl = 'http://127.0.0.1:3000/api/v1';
      final apiClient = AppTorneosApiClient(baseUrl: baseUrl);
      final usuariosApi = UsuariosApi(baseUrl: baseUrl);

      // Detectar si es email o username
      final isEmail = input.contains('@');
      final queryParams = isEmail ? {'email': input} : {'username': input};
      final res = await apiClient.getRaw('/usuarios', queryParameters: queryParams);
      final data = res.data;
      if (data is! List || data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no encontrado.')),
        );
        setState(() => _loading = false);
        return;
      }
      final idUsuarioInvitado = int.tryParse(data[0]['id_usuario'].toString());
      if (idUsuarioInvitado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID de usuario inválido.')),
        );
        setState(() => _loading = false);
        return;
      }

      // Obtener ID del usuario invitador (organizador)
      final userMap = await JwtStorage.getUser();
      int? idUsuarioInvitador;
      if (userMap != null && userMap['id_usuario'] != null) {
        final rawId = userMap['id_usuario'];
        if (rawId is int) {
          idUsuarioInvitador = rawId;
        } else if (rawId is String) {
          idUsuarioInvitador = int.tryParse(rawId);
        }
      }
      if (idUsuarioInvitador == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener tu usuario.')),
        );
        setState(() => _loading = false);
        return;
      }

      // Hacer POST para invitar
      await apiClient.postRaw(
        '/invitaciones/arbitro',
        body: {
          'id_torneo': widget.torneoId,
          'id_usuario_invitado': idUsuarioInvitado,
          'id_usuario_invitador': idUsuarioInvitador,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitación enviada correctamente.')),
      );
      _arbitroController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al invitar árbitro: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de árbitros'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.torneoNombre,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            const Text(
              'Árbitros actuales:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Aquí se mostrarán los árbitros actuales...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Invitar árbitro',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _arbitroController,
                    decoration: const InputDecoration(
                      labelText: 'Email o nombre de usuario',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_loading,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () => _invitarArbitro(context),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Invitar árbitro'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
