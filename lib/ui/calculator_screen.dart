import 'package:flutter/material.dart';
import '../models/glass.dart';
import '../models/glazing_unit.dart';
import '../models/spacer.dart';
import '../services/solar_calculator.dart';
import '../services/thermal_calculator.dart';
import 'widgets/frame_selector.dart';
import 'widgets/glass_selector.dart';
import 'widgets/result_card.dart';
import 'widgets/solar_result_card.dart';
import 'widgets/spacer_selector.dart';
import 'widgets/unit_type_selector.dart';

/// Главный экран калькулятора стеклопакетов.
///
/// Содержит две вкладки:
///   1. Теплопередача — расчёт R₀ и Ug по EN 673
///   2. Солнечный фактор — расчёт g по EN 410 / EN 13363-1
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  // ── Вкладки ───────────────────────────────────────────────────────────────
  late final TabController _tabController;

  // ── Общее состояние (стёкла / камеры) ─────────────────────────────────────
  GlazingUnitType _unitType = GlazingUnitType.single;

  GlassType _glass1 = GlassCatalog.all[0]; // 4 мм флоат
  GlassType _glass2 = GlassCatalog.all[2]; // 4i Low-E
  GlassType _glass3 = GlassCatalog.all[0]; // 4 мм флоат

  SpacerConfig _spacer1 = const SpacerConfig(thicknessMm: 16, gasId: 'air');
  SpacerConfig _spacer2 = const SpacerConfig(thicknessMm: 16, gasId: 'air');

  // ── Результаты ────────────────────────────────────────────────────────────
  ThermalResult? _thermalResult;
  SolarResult? _solarResult;
  String _formula = '';

  // ── Сервисы ───────────────────────────────────────────────────────────────
  final _thermalCalculator = ThermalCalculator();
  final _solarCalculator = SolarCalculator();

  // ── Параметры рамы и окна (для солнечного расчёта) ────────────────────────
  FrameConfig _frameConfig = const FrameConfig(
    frameWidthM: 0.085,
    frameType: FrameType.whitePvc,
  );
  WindowDimensions _windowDimensions = const WindowDimensions(
    widthM: 1.20,
    heightM: 1.40,
  );

  /// Включать ли расчёт g окна с рамой
  bool _includeFrame = true;

  final _scrollController = ScrollController();

  // ── Жизненный цикл ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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

  // ── Расчёты ───────────────────────────────────────────────────────────────
  void _calculateThermal() {
    final unit = _buildUnit();
    setState(() {
      _thermalResult = _thermalCalculator.calculate(unit);
      _formula = unit.formula;
    });
    _scrollToBottom();
  }

  void _calculateSolar() {
    final unit = _buildUnit();
    setState(() {
      _formula = unit.formula;
      if (_includeFrame) {
        _solarResult = _solarCalculator.calculateWindow(
          unit: unit,
          window: _windowDimensions,
          frame: _frameConfig,
        );
      } else {
        _solarResult = _solarCalculator.calculateGlazing(unit);
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _reset() {
    setState(() {
      _thermalResult = null;
      _solarResult = null;
      _formula = '';
    });
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор стеклопакетов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Сбросить',
            onPressed: _reset,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.thermostat_outlined),
              text: 'Теплопередача',
            ),
            Tab(
              icon: Icon(Icons.wb_sunny_outlined),
              text: 'Солнечный фактор g',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Вкладка 1: Теплопередача ─────────────────────────────────────
          _buildScrollBody(
            isWide: isWide,
            children: [
              ..._buildCommonInputs(isWide: isWide),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _calculateThermal,
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Рассчитать R₀ и Ug'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              if (_thermalResult != null) ...[
                const SizedBox(height: 28),
                const _SectionLabel('Результат'),
                ResultCard(formula: _formula, result: _thermalResult!),
              ],
              const SizedBox(height: 32),
            ],
          ),

          // ── Вкладка 2: Солнечный фактор ──────────────────────────────────
          _buildScrollBody(
            isWide: isWide,
            children: [
              ..._buildCommonInputs(isWide: isWide),
              const SizedBox(height: 24),

              // Переключатель: только стеклопакет / с рамой
              const _SectionLabel('Расчёт g окна с рамой'),
              SwitchListTile(
                value: _includeFrame,
                onChanged: (v) => setState(() {
                  _includeFrame = v;
                  _solarResult = null;
                }),
                title: const Text('Учитывать параметры рамы'),
                subtitle: Text(_includeFrame
                    ? 'Рассчитать ggl и gw (EN 13363-1)'
                    : 'Рассчитать только ggl стеклопакета (EN 410)'),
                contentPadding: EdgeInsets.zero,
              ),

              if (_includeFrame) ...[
                const SizedBox(height: 16),
                FrameSelector(
                  frameConfig: _frameConfig,
                  windowDimensions: _windowDimensions,
                  onFrameChanged: (v) => setState(() {
                    _frameConfig = v;
                    _solarResult = null;
                  }),
                  onWindowChanged: (v) => setState(() {
                    _windowDimensions = v;
                    _solarResult = null;
                  }),
                ),
              ],

              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _calculateSolar,
                icon: const Icon(Icons.wb_sunny_outlined),
                label: const Text('Рассчитать солнечный фактор g'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),

              if (_solarResult != null) ...[
                const SizedBox(height: 28),
                const _SectionLabel('Результат'),
                SolarResultCard(formula: _formula, result: _solarResult!),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }

  // ── Общие блоки ввода (стёкла и камеры) ──────────────────────────────────
  List<Widget> _buildCommonInputs({required bool isWide}) {
    return [
      const _SectionLabel('Тип стеклопакета'),
      UnitTypeSelector(
        selected: _unitType,
        onChanged: (t) => setState(() {
          _unitType = t;
          _thermalResult = null;
          _solarResult = null;
        }),
      ),
      const SizedBox(height: 24),
      const _SectionLabel('Стёкла'),
      if (isWide) _buildGlassRow() else _buildGlassColumn(),
      const SizedBox(height: 24),
      const _SectionLabel('Газовые камеры'),
      _buildSpacers(isWide: isWide),
    ];
  }

  Widget _buildScrollBody({
    required bool isWide,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
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
            children: children,
          ),
        ),
      ),
    );
  }

  // ── Стёкла ────────────────────────────────────────────────────────────────
  Widget _buildGlassRow() {
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
        onChanged: (v) => setState(() {
          _glass1 = v;
          _thermalResult = null;
          _solarResult = null;
        }),
      ),
      GlassSelector(
        label: _unitType == GlazingUnitType.single
            ? 'Стекло 2 (внутреннее)'
            : 'Стекло 2 (среднее)',
        selected: _glass2,
        onChanged: (v) => setState(() {
          _glass2 = v;
          _thermalResult = null;
          _solarResult = null;
        }),
      ),
    ];
    if (_unitType == GlazingUnitType.double_) {
      selectors.add(GlassSelector(
        label: 'Стекло 3 (внутреннее)',
        selected: _glass3,
        onChanged: (v) => setState(() {
          _glass3 = v;
          _thermalResult = null;
          _solarResult = null;
        }),
      ));
    }
    return selectors;
  }

  // ── Камеры ────────────────────────────────────────────────────────────────
  Widget _buildSpacers({required bool isWide}) {
    if (_unitType == GlazingUnitType.single) {
      return SpacerSelector(
        label: 'Камера 1',
        config: _spacer1,
        onChanged: (v) => setState(() {
          _spacer1 = v;
          _thermalResult = null;
          _solarResult = null;
        }),
      );
    }

    final spacer1Widget = SpacerSelector(
      label: 'Камера 1 (между стеклом 1 и 2)',
      config: _spacer1,
      onChanged: (v) => setState(() {
        _spacer1 = v;
        _thermalResult = null;
        _solarResult = null;
      }),
    );
    final spacer2Widget = SpacerSelector(
      label: 'Камера 2 (между стеклом 2 и 3)',
      config: _spacer2,
      onChanged: (v) => setState(() {
        _spacer2 = v;
        _thermalResult = null;
        _solarResult = null;
      }),
    );

    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: spacer1Widget),
              const SizedBox(width: 12),
              Expanded(child: spacer2Widget),
            ],
          )
        : Column(children: [
            spacer1Widget,
            const SizedBox(height: 12),
            spacer2Widget,
          ]);
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
