import 'package:flutter/material.dart';
import '../../models/gas.dart';
import '../../models/spacer.dart';

/// Выбор параметров одной газовой камеры:
/// ширина дистанции, тип газа, тип рамки.
class SpacerSelector extends StatelessWidget {
  final String label;
  final SpacerConfig config;
  final ValueChanged<SpacerConfig> onChanged;

  const SpacerSelector({
    super.key,
    required this.label,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок камеры
            Row(
              children: [
                Icon(Icons.air, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: cs.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Параметры в строку: расстояние, газ, дистанционный профиль
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ширина дистанции
                Expanded(
                  child: _paramColumn(
                    context: context,
                    label: 'Расстояние между стёклами',
                    child: DropdownButtonFormField<int>(
                      value: config.thicknessMm,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.straighten_outlined, size: 20),
                      ),
                      items: SpacerConfig.availableThicknesses
                          .map((mm) => DropdownMenuItem(
                                value: mm,
                                child: Text('$mm мм'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) onChanged(config.copyWith(thicknessMm: v));
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Газ-наполнитель
                Expanded(
                  child: _paramColumn(
                    context: context,
                    label: 'Газ-наполнитель',
                    child: DropdownButtonFormField<String>(
                      value: config.gasId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.bubble_chart_outlined, size: 20),
                      ),
                      items: GasCatalog.all
                          .map((g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(g.label),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) onChanged(config.copyWith(gasId: v));
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Тип дистанционного профиля
                Expanded(
                  child: _paramColumn(
                    context: context,
                    label: 'Дистанционный профиль',
                    child: SegmentedButton<SpacerFrameType>(
                      segments: SpacerFrameType.values
                          .map((f) => ButtonSegment(
                                value: f,
                                label: Text(f.label),
                              ))
                          .toList(),
                      selected: {config.frameType},
                      onSelectionChanged: (s) =>
                          onChanged(config.copyWith(frameType: s.first)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paramColumn({
    required BuildContext context,
    required String label,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
