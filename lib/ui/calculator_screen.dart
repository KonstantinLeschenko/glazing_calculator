import 'package:flutter/material.dart';
import '../models/glass.dart';
import '../models/glazing_unit.dart';
import '../models/spacer.dart';
import '../services/thermal_calculator.dart';
import 'widgets/glass_selector.dart';
import 'widgets/result_card.dart';
import 'widgets/spacer_selector.dart';
import 'widgets/unit_type_selector.dart';

/// Главный экран калькулятора стеклопакетов.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // ── Состояние ──────────────────────────────────────────────────────────────
  GlazingUnitType _unitType = GlazingUnitType.single;

  GlassType _glass1 = GlassCatalog.all[0]; // 4 мм флоат
  GlassType _glass2 = GlassCatalog.all[2]; // 4i Low-E
  GlassType _glass3 = GlassCatalog.all[0]; // 4 мм флоат

  SpacerConfig _spacer1 = const SpacerConfig(thicknessMm: 16, gasId: 'air');
  SpacerConfig _spacer2 = const SpacerConfig(thicknessMm: 16, gasId: 'air');

  ThermalResult? _result;
  String _formula = '';

  final _calculator = ThermalCalculator();
  final _scrollController = ScrollController();

  // ── Расчёт ────────────────────────────────────────────────────────────────
  void _calculate() {
    final GlazingUnit unit;

    if (_unitType == GlazingUnitType.single) {
      unit = GlazingUnit.single(
        glass1: _glass1,
        spacer1: _spacer1,
        glass2: _glass2,
      );
    } else {
      unit = GlazingUnit.double_(
        glass1: _glass1,
        spacer1: _spacer1,
        glass2: _glass2,
        spacer2: _spacer2,
        glass3: _glass3,
      );
    }

    setState(() {
      _result = _calculator.calculate(unit);
      _formula = unit.formula;
    });

    // Прокрутка к результату
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  // ── Построение UI ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор стеклопакетов'),
        actions: [
          // Кнопка сброса
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Сбросить',
            onPressed: () => setState(() {
              _result = null;
              _formula = '';
            }),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 32 : 16,
          vertical: 20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Тип стеклопакета ──────────────────────────────────────
                const _SectionLabel('Тип стеклопакета'),
                UnitTypeSelector(
                  selected: _unitType,
                  onChanged: (t) => setState(() {
                    _unitType = t;
                    _result = null;
                  }),
                ),

                const SizedBox(height: 24),

                // ── Стёкла ────────────────────────────────────────────────
                const _SectionLabel('Стёкла'),
                if (isWide)
                  _buildGlassRow(isWide: true)
                else
                  _buildGlassColumn(),

                const SizedBox(height: 24),


// ── Камеры...────────────────────────────────────────────────
                const _SectionLabel('Газовые камеры'),
                if (_unitType == GlazingUnitType.single)
                  SpacerSelector(
                    label: 'Камера 1',
                    config: _spacer1,
                    onChanged: (v) => setState(() => _spacer1 = v),
                  )
                else
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SpacerSelector(
                                label: 'Камера 1 (между стеклом 1 и 2)',
                                config: _spacer1,
                                onChanged: (v) =>
                                    setState(() => _spacer1 = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SpacerSelector(
                                label: 'Камера 2 (между стеклом 2 и 3)',
                                config: _spacer2,
                                onChanged: (v) =>
                                    setState(() => _spacer2 = v),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            SpacerSelector(
                              label: 'Камера 1 (между стеклом 1 и 2)',
                              config: _spacer1,
                              onChanged: (v) => setState(() => _spacer1 = v),
                            ),
                            const SizedBox(height: 12),
                            SpacerSelector(
                              label: 'Камера 2 (между стеклом 2 и 3)',
                              config: _spacer2,
                              onChanged: (v) => setState(() => _spacer2 = v),
                            ),
                          ],
                        ),

                const SizedBox(height: 24),

                // ── Кнопка расчёта ────────────────────────────────────────
                FilledButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Рассчитать'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),

                // ── Результат ─────────────────────────────────────────────
                if (_result != null) ...[
                  const SizedBox(height: 28),
                  const _SectionLabel('Результат'),
                  ResultCard(formula: _formula, result: _result!),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Вспомогательные методы ────────────────────────────────────────────────

  Widget _buildGlassRow({required bool isWide}) {
    final glasses = _getGlassSelectors();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < glasses.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: glasses[i]),
        ],
      ],
    );
  }

  Widget _buildGlassColumn() {
    final glasses = _getGlassSelectors();
    return Column(
      children: [
        for (int i = 0; i < glasses.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          glasses[i],
        ],
      ],
    );
  }
  List<Widget> _getGlassSelectors() {
    final selectors = <Widget>[
      GlassSelector(
        label: 'Стекло 1 (наружное)',
        selected: _glass1,
        onChanged: (v) => setState(() => _glass1 = v),
      ),
      GlassSelector(
        label: _unitType == GlazingUnitType.single
            ? 'Стекло 2 (внутреннее)'
            : 'Стекло 2 (среднее)',
        selected: _glass2,
        onChanged: (v) => setState(() => _glass2 = v),
      ),
    ];
    if (_unitType == GlazingUnitType.double_) {
      selectors.add(GlassSelector(
        label: 'Стекло 3 (внутреннее)',
        selected: _glass3,
        onChanged: (v) => setState(() => _glass3 = v),
      ));
    }
    return selectors;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// ── Метка раздела ────────────────────────────────────────────────────────────
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