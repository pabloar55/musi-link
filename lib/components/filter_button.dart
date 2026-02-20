import 'package:flutter/material.dart';

/// Botón reutilizable para filtros tipo toggle (tracks/artists, time range).
/// Se muestra como "activo" (primary) cuando [isSelected] es true.
class FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const FilterButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton(
      onPressed: isSelected ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: padding,
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurface,
        disabledBackgroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onPrimary,
      ),
      child: Text(label, style: TextStyle(fontSize: fontSize)),
    );
  }
}
