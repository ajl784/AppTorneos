import 'package:flutter/material.dart';

class CategoriaNetworkAvatar extends StatelessWidget {
  final int categoriaId;
  final String baseUrl;
  final double size;

  const CategoriaNetworkAvatar({
    super.key,
    required this.categoriaId,
    required this.baseUrl,
    this.size = 32,
  });

  String get _iconUrl =>
      '${baseUrl.replaceAll('/api/v1', '')}/api/v1/categorias/$categoriaId/icono';

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
      child: Icon(Icons.category, size: size * 0.6),
    );
  }
}