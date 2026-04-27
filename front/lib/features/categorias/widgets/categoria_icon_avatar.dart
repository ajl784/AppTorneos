import 'package:flutter/material.dart';
import 'package:front/features/categorias/domain/categoria.dart';

class CategoriaIconAvatar extends StatelessWidget {
  final Categoria categoria;
  final String baseUrl;
  final double size;

  const CategoriaIconAvatar({
    super.key,
    required this.categoria,
    required this.baseUrl,
    this.size = 32,
  });

  String get _iconUrl =>
      '${baseUrl.replaceAll('/api/v1', '')}/api/v1/categorias/${categoria.idCategoria}/icono';

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: categoria.tieneIcono
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
      child: Icon(Icons.category, size: size * 0.6),
    );
  }
}