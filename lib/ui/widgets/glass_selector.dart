import 'package:flutter/material.dart';
import '../../models/glass.dart';

/// Выпадающий список выбора типа стекла.
class GlassSelector extends StatelessWidget {
  final String label;
  final GlassType selected;
  final ValueChanged<GlassType> onChanged;
  final bool verticalChips;

  const GlassSelector({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.verticalChips = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<GlassType>(
          value: selected,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.window_outlined, size: 20),
          ),
          items: GlassCatalog.all.map((g) {
            return DropdownMenuItem(
              value: g,
              child: Text(g.description, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
        // Краткая характеристика выбранного стекла
        const SizedBox(height: 4),
        if (verticalChips)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chip(context, 'd = ${(selected.thickness * 1000).toStringAsFixed(1)} мм'),
              const SizedBox(height: 4),
              _chip(context, 'ε = ${selected.emissivity}'),
              const SizedBox(height: 4),
              _chip(context, 'λ = ${selected.lambda} Вт/(м·К)'),
            ],
          )
        else
          Row(
            children: [
              _chip(context, 'd = ${(selected.thickness * 1000).toStringAsFixed(1)} мм'),
              const SizedBox(width: 6),
              _chip(context, 'ε = ${selected.emissivity}'),
              const SizedBox(width: 6),
              _chip(context, 'λ = ${selected.lambda} Вт/(м·К)'),
            ],
          ),
      ],
    );
  }

  Widget _chip(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSecondaryContainer,
            ),
      ),
    );
  }
}