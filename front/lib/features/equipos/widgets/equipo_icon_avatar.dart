import 'package:flutter/material.dart';
import 'package:front/features/equipos/domain/equipo.dart';

class EquipoIconAvatar extends StatelessWidget {
  final Equipo equipo;
  final String baseUrl;
  final double size;

  const EquipoIconAvatar({
    super.key,
    required this.equipo,
    required this.baseUrl,
    this.size = 32,
  });

  String get _iconUrl =>
      '${baseUrl.replaceAll('/api/v1', '')}/api/v1/equipos/${equipo.idEquipo}/icono';

  bool get _tieneIcono => equipo.iconoUrl != null && equipo.iconoUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: _tieneIcono
            ? Image.network(
                _iconUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(context),
              )
            : _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.groups, size: size * 0.6),
    );
  }
}
