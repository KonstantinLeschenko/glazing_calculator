import 'package:flutter/material.dart';
import '../../services/solar_calculator.dart';
import '../../services/thermal_calculator.dart';
import 'energy_label_card.dart';
import 'result_card.dart' as thermal;
import 'solar_result_card.dart' as solar;

/// Карточка результатов с вкладками "Теплопередача", "Солнечный фактор" и "Этикетка".
///
/// Показывает формулу стеклопакета и три таба с результатами расчётов.
class ResultTabsCard extends StatelessWidget {
  final String formula;
  final ThermalResult thermalResult;
  final SolarResult solarResult;

  const ResultTabsCard({
    super.key,
    required this.formula,
    required this.thermalResult,
    required this.solarResult,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Формула стеклопакета ──────────────────────────────────────────
          Text(
            'Формула стеклопакета',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondaryContainer
                  .withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              formula,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Вкладки ──────────────────────────────────────────────────────
          TabBar(
            tabs: const [
              Tab(
                icon: Icon(Icons.thermostat_outlined),
                text: 'Теплопередача',
              ),
              Tab(
                icon: Icon(Icons.wb_sunny_outlined),
                text: 'Солнечный фактор',
              ),
              Tab(
                icon: Icon(Icons.energy_savings_leaf_outlined),
                text: 'Этикетка',
              ),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),

          const SizedBox(height: 12),

          // ── Содержимое вкладок ───────────────────────────────────────────
          SizedBox(
            // Ограничиваем высоту, чтобы диалог не уходил за экран
            height: 500,
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  child: thermal.ResultCard(
                    formula: formula,
                    result: thermalResult,
                  ),
                ),
                SingleChildScrollView(
                  child: solar.SolarResultCard(
                    formula: formula,
                    result: solarResult,
                  ),
                ),
                SingleChildScrollView(
                  child: EnergyLabelCard(
                    ug: thermalResult.ug,
                    ggl: solarResult.glazing.ggl,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}