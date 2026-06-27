import 'package:flutter/material.dart';
import '../../services/solar_calculator.dart';

/// Карточка результатов расчёта солнечного фактора g (EN 410 / EN 13363-1).
class SolarResultCard extends StatelessWidget {
  final String formula;
  final SolarResult result;

  const SolarResultCard({
    super.key,
    required this.formula,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final g = result.glazing;

    return Card(
      color: cs.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Формула стеклопакета ──────────────────────────────────────
            Text('Формула стеклопакета',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

            // ── Главные показатели: ggl и τe ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _MainMetric(
                    label: 'ggl',
                    value: g.ggl.toStringAsFixed(2),
                    unit: 'солнечный фактор\nстеклопакета',
                    color: _colorForG(cs, g.ggl),
                    tooltip: 'Суммарный коэффициент солнечного\nтеплопоступления стеклопакета (EN 410)',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MainMetric(
                    label: 'τe',
                    value: g.tauE.toStringAsFixed(3),
                    unit: 'прямое\nпропускание',
                    color: cs.onSurface,
                    tooltip: 'Коэффициент прямого пропускания\nсолнечного излучения стеклопакетом',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MainMetric(
                    label: 'qi',
                    value: g.qi.toStringAsFixed(3),
                    unit: 'вторичная\nтеплоотдача',
                    color: cs.onSurface,
                    tooltip: 'Вторичный коэффициент теплопередачи\nвнутрь помещения',
                  ),
                ),
              ],
            ),

            // ── Блок g окна (если рассчитан) ──────────────────────────────
            if (result.gw != null) ...[
              const SizedBox(height: 16),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: 12),

              Text('Солнечный фактор окна в целом (EN 13363-1)',
                  style: tt.labelMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _MainMetric(
                      label: 'gw',
                      value: result.gw!.toStringAsFixed(2),
                      unit: 'окно с рамой',
                      color: _colorForG(cs, result.gw!),
                      tooltip: 'Суммарный солнечный фактор окна\n(остекление + рама)',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MainMetric(
                      label: 'gf',
                      value: result.gf!.toStringAsFixed(3),
                      unit: 'рама',
                      color: cs.onSurface,
                      tooltip: 'Солнечный фактор рамы',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MainMetric(
                      label: 'Ff',
                      value:
                          '${(result.glazingFraction! * 100).toStringAsFixed(1)}%',
                      unit: 'доля\nостекления',
                      color: cs.onSurface,
                      tooltip: 'Доля площади остекления в общей\nплощади окна',
                    ),
                  ),
                ],
              ),

              // Площади
              const SizedBox(height: 10),
              _AreaRow(
                aGlazing: result.aGlazing!,
                aFrame: result.aFrame!,
              ),
            ],

            const SizedBox(height: 20),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 12),

            // ── Разбивка поглощения по стёклам ────────────────────────────
            Text('Разбивка поглощения солнечного излучения',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),

            _AbsorptionRow(label: 'Стекло 1 (A₁)', value: g.a1),
            _AbsorptionRow(label: 'Стекло 2 (A₂)', value: g.a2),
            if (g.a3 != null)
              _AbsorptionRow(label: 'Стекло 3 (A₃)', value: g.a3!),
            _AbsorptionRow(label: 'Прямое пропускание (τe)', value: g.tauE),
            _AbsorptionRow(label: 'Отражение (ρe)', value: g.rhoE),

            const SizedBox(height: 16),

            // ── Сноска ────────────────────────────────────────────────────
            Text(
              'Расчёт по EN 410:2011 (стеклопакет) и EN 13363-1:2007 (окно). '
              'Нормальное падение (θ = 0°). '
              'Граничные условия: he = 23, hi = 8 Вт/(м²·К).',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForG(ColorScheme cs, double g) {
    if (g <= 0.30) return const Color(0xFF0F6E56); // очень хорошая защита
    if (g <= 0.45) return const Color(0xFF185FA5); // хорошая защита
    if (g <= 0.60) return const Color(0xFF854F0B); // средняя
    return cs.error;                                // высокий нагрев
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
            Text(
              unit,
              style: tt.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AbsorptionRow extends StatelessWidget {
  final String label;
  final double value;

  const _AbsorptionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              Text(
                value.toStringAsFixed(4),
                style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
            backgroundColor: cs.surfaceVariant,
            color: cs.tertiary.withOpacity(0.6),
          ),
        ],
      ),
    );
  }
}

class _AreaRow extends StatelessWidget {
  final double aGlazing;
  final double aFrame;

  const _AreaRow({required this.aGlazing, required this.aFrame});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final total = aGlazing + aFrame;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _areaCell(context, 'Остекление Ag',
              '${aGlazing.toStringAsFixed(4)} м²', cs, tt),
          _areaCell(context, 'Рама Af',
              '${aFrame.toStringAsFixed(4)} м²', cs, tt),
          _areaCell(context, 'Окно Aw',
              '${total.toStringAsFixed(4)} м²', cs, tt),
        ],
      ),
    );
  }

  Widget _areaCell(BuildContext context, String label, String value,
      ColorScheme cs, TextTheme tt) {
    return Column(
      children: [
        Text(label,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        Text(value, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
