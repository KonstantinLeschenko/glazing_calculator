import 'package:flutter/material.dart';
import '../../services/sound_calculator.dart';

/// Карточка с результатами оценки звукоизоляции (Rw) стеклопакета.
class SoundResultCard extends StatelessWidget {
  final String formula;
  final SoundResult result;

  const SoundResultCard({
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

            // Главный показатель
            Row(
              children: [
                Expanded(
                  child: _MainMetric(
                    label: 'Rw',
                    value: result.rw.toStringAsFixed(1),
                    unit: 'дБ',
                    color: _colorForRw(cs, result.rw),
                    tooltip: 'Расчётная оценка индекса звукоизоляции',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MainMetric(
                    label: 'Оценка',
                    value: _ratingText(result.rw),
                    unit: '',
                    color: _colorForRw(cs, result.rw),
                    tooltip: 'Ориентировочная оценка звукоизоляции',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 12),

            // Разбивка расчёта
            Text('Разбивка расчёта',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),
            ...result.layers.map((layer) => _LayerRow(layer: layer)),

            const SizedBox(height: 8),
            Divider(color: cs.outlineVariant, height: 1),
            const SizedBox(height: 8),

            // Итоговая строка
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rw итого',
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  '${result.rw.toStringAsFixed(1)} дБ',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Сноска
            Text(
              'Расчётная инженерная оценка на основе модели резонанса '
              '«масса-воздух-масса» (аналог модели Sharp, ISO 12354-1). '
              'EN 12758 не даёт замкнутой формулы для Rw — официальное '
              'значение подтверждается только лабораторными испытаниями '
              'по EN ISO 10140.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForRw(ColorScheme cs, double rw) {
    if (rw >= 35) return const Color(0xFF0F6E56);
    if (rw >= 30) return const Color(0xFF185FA5);
    if (rw >= 27) return const Color(0xFF854F0B);
    return cs.error;
  }

  String _ratingText(double rw) {
    if (rw >= 35) return 'Отлично';
    if (rw >= 30) return 'Хорошо';
    if (rw >= 27) return 'Удовл.';
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
  final SoundLayer layer;

  const _LayerRow({required this.layer});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(layer.label,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(
            layer.value,
            style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
