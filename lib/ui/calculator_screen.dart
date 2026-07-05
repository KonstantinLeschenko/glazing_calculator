import 'package:flutter/material.dart';
import '../models/glass.dart';
import '../models/glazing_unit.dart';
import '../models/spacer.dart';
import '../services/solar_calculator.dart';
import '../services/thermal_calculator.dart';
import 'widgets/result_tabs_card.dart';
import 'widgets/spacer_selector.dart';
import 'widgets/unit_type_selector.dart';
import 'widgets/glass_selector.dart';

/// Главный экран калькулятора стеклопакетов.
///
/// Единая форма ввода параметров стеклопакета.
/// Результаты: вкладки "Теплопередача" и "Солнечный фактор" в диалоге.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // ── Общее состояние (стёкла / камеры) ─────────────────────────────────────
  GlazingUnitType _unitType = GlazingUnitType.single;
  GlassType _glass1 = GlassCatalog.all[0]; // 4 мм флоат
  GlassType _glass2 = GlassCatalog.all[2]; // 4i Low-E
  GlassType _glass3 = GlassCatalog.all[0]; // 4 мм флоат
  SpacerConfig _spacer1 = const SpacerConfig(thicknessMm: 16, gasId: 'air');
  SpacerConfig _spacer2 = const SpacerConfig(thicknessMm: 16, gasId: 'air');

  // ── Сервисы ───────────────────────────────────────────────────────────────
  final _thermalCalculator = ThermalCalculator();
  final _solarCalculator = SolarCalculator();

  // ── Построение GlazingUnit из текущего состояния ─────────────────────────
  GlazingUnit _buildUnit() {
    if (_unitType == GlazingUnitType.single) {
      return GlazingUnit.single(
        glass1: _glass1,
        spacer1: _spacer1,
        glass2: _glass2,
      );
    } else {
      return GlazingUnit.double_(
        glass1: _glass1,
        spacer1: _spacer1,
        glass2: _glass2,
        spacer2: _spacer2,
        glass3: _glass3,
      );
    }
  }

  // ── Расчёт ────────────────────────────────────────────────────────────────
  void _calculate() {
    final unit = _buildUnit();
    final formula = unit.formula;

    // Теплотехнический расчёт
    final thermalResult = _thermalCalculator.calculate(unit);

    // Солнечный расчёт (только для стеклопакета)
    final solarResult = _solarCalculator.calculateGlazing(unit);

    _showResultDialog(
      title: 'Результаты расчёта',
      child: ResultTabsCard(
        formula: formula,
        thermalResult: thermalResult,
        solarResult: solarResult,
      ),
    );
  }

  /// Показывает диалог с карточкой результата расчёта.
  void _showResultDialog({
    required String title,
    required Widget child,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(ctx).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: child,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Закрыть'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор стеклопакетов'),
      ),
      body: _buildScrollBody(
        isLandscape: isLandscape,
        children: [
          const _SectionLabel('Тип стеклопакета'),
          UnitTypeSelector(
            selected: _unitType,
            onChanged: (t) => setState(() {
              _unitType = t;
            }),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Состав стеклопакета'),
          ..._buildInputWidgets(isLandscape: isLandscape),
          const SizedBox(height: 24),

          // ── Кнопка расчёта ────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Рассчитать'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildScrollBody({
    required bool isLandscape,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 32 : 16,
        vertical: 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }

  /// Строит список виджетов «Стекло → Камера → Стекло → …» в правильном
  /// порядке в зависимости от типа стеклопакета и ориентации экрана.
  List<Widget> _buildInputWidgets({required bool isLandscape}) {
    const gapV = SizedBox(height: 16);
    const gapH = SizedBox(width: 16);

    if (_unitType == GlazingUnitType.single) {
      if (isLandscape) {
        return [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GlassSelector(
                  label: 'Стекло 1 (наружное)',
                  selected: _glass1,
                  onChanged: (v) => setState(() => _glass1 = v),
                  verticalChips: true,
                ),
              ),
              gapH,
              Expanded(
                child: SpacerSelector(
                  label: 'Камера 1',
                  config: _spacer1,
                  onChanged: (v) => setState(() => _spacer1 = v),
                  compact: true,
                ),
              ),
              gapH,
              Expanded(
                child: GlassSelector(
                  label: 'Стекло 2 (внутреннее)',
                  selected: _glass2,
                  onChanged: (v) => setState(() => _glass2 = v),
                  verticalChips: true,
                ),
              ),
            ],
          ),
        ];
      }
      return [
        GlassSelector(
          label: 'Стекло 1 (наружное)',
          selected: _glass1,
          onChanged: (v) => setState(() => _glass1 = v),
        ),
        gapV,
        SpacerSelector(
          label: 'Камера 1',
          config: _spacer1,
          onChanged: (v) => setState(() => _spacer1 = v),
        ),
        gapV,
        GlassSelector(
          label: 'Стекло 2 (внутреннее)',
          selected: _glass2,
          onChanged: (v) => setState(() => _glass2 = v),
        ),
      ];
    }

    if (isLandscape) {
      return [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GlassSelector(
                label: 'Стекло 1 (наружное)',
                selected: _glass1,
                onChanged: (v) => setState(() => _glass1 = v),
                verticalChips: true,
              ),
            ),
            gapH,
            Expanded(
              child: SpacerSelector(
                label: 'Камера 1',
                config: _spacer1,
                onChanged: (v) => setState(() => _spacer1 = v),
                compact: true,
              ),
            ),
            gapH,
            Expanded(
              child: GlassSelector(
                label: 'Стекло 2 (среднее)',
                selected: _glass2,
                onChanged: (v) => setState(() => _glass2 = v),
                verticalChips: true,
              ),
            ),
            gapH,
            Expanded(
              child: SpacerSelector(
                label: 'Камера 2',
                config: _spacer2,
                onChanged: (v) => setState(() => _spacer2 = v),
                compact: true,
              ),
            ),
            gapH,
            Expanded(
              child: GlassSelector(
                label: 'Стекло 3 (внутреннее)',
                selected: _glass3,
                onChanged: (v) => setState(() => _glass3 = v),
                verticalChips: true,
              ),
            ),
          ],
        ),
      ];
    }

    return [
      GlassSelector(
        label: 'Стекло 1 (наружное)',
        selected: _glass1,
        onChanged: (v) => setState(() => _glass1 = v),
      ),
      gapV,
      SpacerSelector(
        label: 'Камера 1',
        config: _spacer1,
        onChanged: (v) => setState(() => _spacer1 = v),
      ),
      gapV,
      GlassSelector(
        label: 'Стекло 2 (среднее)',
        selected: _glass2,
        onChanged: (v) => setState(() => _glass2 = v),
      ),
      gapV,
      SpacerSelector(
        label: 'Камера 2',
        config: _spacer2,
        onChanged: (v) => setState(() => _spacer2 = v),
      ),
      gapV,
      GlassSelector(
        label: 'Стекло 3 (внутреннее)',
        selected: _glass3,
        onChanged: (v) => setState(() => _glass3 = v),
      ),
    ];
  }
}

// ── Метка раздела ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}