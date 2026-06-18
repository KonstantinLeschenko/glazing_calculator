import 'package:flutter/material.dart';
import '../../services/thermal_calculator.dart';

/// Карточка с результатами расчёта.
class ResultCard extends StatelessWidget {
  final String formula;
  final ThermalResult result;

  const ResultCard({
    super.key,
    required this.formula,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      color: cs.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Формула
            Text('Формула стеклопакета',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                formula,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Главные показатели
            Row(
              children: [
                Expanded(
                  child: _MainMetric(
                    label: 'R₀',
                    value: result.r0.toStringAsFixed(3),
                    unit: 'м²·°C/Вт',
                    color: _colorForR0(cs, result.r0),
                    tooltip: 'Сопротивление теплопередачи центральной зоны',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MainMetric(
                    label: 'Ug',
                    value: result.ug.toStringAsFixed(2),
                    unit: 'Вт/(м²·К)',
                    color: cs.onSurface,
                    tooltip: 'Коэффициент теплопередачи (EN 673)',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MainMetric(
                    label: 'Оценка',
                    value: _ratingText(result.r0),
                    unit: '',
                    color: _colorForR0(cs, result.r0),
                    tooltip: 'Ориентировочная оценка теплозащиты',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 12),

            // Разбивка по слоям
            Text('Разбивка термического сопротивления',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),
            ...result.layers.map((layer) => _LayerRow(layer: layer, total: result.r0)),

            const SizedBox(height: 8),
            Divider(color: cs.outlineVariant, height: 1),
            const SizedBox(height: 8),

            // Итоговая строка
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('R₀ итого',
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  '${result.r0.toStringAsFixed(4)} м²·К/Вт',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Сноска
            Text(
              'Расчёт по центральной зоне стеклопакета (EN 673). '
              'Тип дистанционного профиля влияет на Rw окна в целом, '
              'но не на R₀ центральной зоны.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForR0(ColorScheme cs, double r0) {
    if (r0 >= 0.80) return const Color(0xFF0F6E56);
    if (r0 >= 0.60) return const Color(0xFF185FA5);
    if (r0 >= 0.45) return const Color(0xFF854F0B);
    return cs.error;
  }

  String _ratingText(double r0) {
    if (r0 >= 0.80) return 'Отлично';
    if (r0 >= 0.60) return 'Хорошо';
    if (r0 >= 0.45) return 'Удовл.';
    return 'Низкое';
  }
}

// ── Вспомогательные виджеты ────────────────────────────────────────────────

class _MainMetric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final String tooltip;

  const _MainMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          children: [
            Text(label,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(
              value,
              style: tt.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (unit.isNotEmpty)
              Text(unit,
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  final ThermalLayer layer;
  final double total;

  const _LayerRow({required this.layer, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fraction = layer.rValue / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(layer.label,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(
                layer.rValue.toStringAsFixed(4),
                style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Прогресс-бар пропорциональный вкладу слоя
          LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
            backgroundColor: cs.surfaceVariant,
            color: cs.primary.withOpacity(0.6),
          ),
        ],
      ),
    );
  }
}