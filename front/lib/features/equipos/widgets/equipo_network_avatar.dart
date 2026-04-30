import 'package:flutter/material.dart';

class EquipoNetworkAvatar extends StatelessWidget {
  final int equipoId;
  final String baseUrl;
  final double size;

  const EquipoNetworkAvatar({
    super.key,
    required this.equipoId,
    required this.baseUrl,
    this.size = 32,
  });

  String get _iconUrl =>
      '${baseUrl.replaceAll('/api/v1', '')}/api/v1/equipos/$equipoId/icono';

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          _iconUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(context),
        ),
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
