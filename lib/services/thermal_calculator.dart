import 'dart:math' as math;
import '../models/gas.dart';
import '../models/glass.dart';
import '../models/glazing_unit.dart';
import '../models/spacer.dart';

/// Результат теплотехнического расчёта стеклопакета.
class ThermalResult {
  /// Термическое сопротивление центральной зоны, м²·К/Вт
  final double r0;

  /// Коэффициент теплопередачи (Ug), Вт/(м²·К)
  final double ug;

  /// Детальная разбивка по слоям для отображения в UI
  final List<ThermalLayer> layers;

  const ThermalResult({
    required this.r0,
    required this.ug,
    required this.layers,
  });
}

/// Один слой (стекло или камера) в разбивке расчёта.
class ThermalLayer {
  final String label;
  final double rValue; // вклад в R₀, м²·К/Вт

  const ThermalLayer(this.label, this.rValue);
}

/// Детальный результат расчёта газовой камеры.
class ChamberResult {
  final double hConvective;   // конвективная составляющая h_c, Вт/(м²·К)
  final double hRadiative;    // радиационная составляющая h_r, Вт/(м²·К)
  final double hTotal;        // суммарный h_s = h_c + h_r, Вт/(м²·К)
  final double thermalR;      // R_s = 1 / h_s, м²·К/Вт

  const ChamberResult({
    required this.hConvective,
    required this.hRadiative,
    required this.hTotal,
    required this.thermalR,
  });
}

/// Сервис расчёта теплотехнических характеристик стеклопакета.
///
/// Методика: EN 673:2011 / ГОСТ Р 54166-2010.
/// Расчёт ведётся для ЦЕНТРАЛЬНОЙ ЗОНЫ стеклопакета (без учёта краевых
/// эффектов дистанционного профиля — они учитываются отдельно при расчёте
/// Rw всей оконной конструкции).
class ThermalCalculator {
  // ── Граничные условия (EN 673, таблица 1) ──────────────────────────────────
  /// Коэффициент теплоотдачи у наружной поверхности, Вт/(м²·К)
  static const double _hExternal = 25.0; // R_se = 1/25 = 0.04 м²·К/Вт

  /// Коэффициент теплоотдачи у внутренней поверхности, Вт/(м²·К)
  static const double _hInternal = 7.7;  // R_si = 1/7.7 = 0.13 м²·К/Вт

  /// Константа Стефана–Больцмана, Вт/(м²·К⁴)
  static const double _sigma = 5.67e-8;

  /// Расчётная средняя температура газового слоя, K
  // ignore: constant_identifier_names
  static const double _Tm = 283.15; // 10°C по EN 673

  /// Расчётный перепад температур на газовом слое, К
  static const double _deltaT = 15.0;

  // ── Публичный API ──────────────────────────────────────────────────────────

  /// Рассчитывает R₀ и Ug стеклопакета по его конфигурации.
  ThermalResult calculate(GlazingUnit unit) {
    final layers = <ThermalLayer>[];

    // 1. Наружное граничное сопротивление
    const rSe = 1.0 / _hExternal;
    layers.add(const ThermalLayer('R_se (наружная поверхность)', rSe));

    // 2. Стекло 1
    final rG1 = _glassResistance(unit.glass1);
    layers.add(ThermalLayer('${unit.glass1.label} (${(unit.glass1.thickness * 1000).toStringAsFixed(1)} мм)', rG1));

    // 3. Камера 1
    final gas1 = _getGas(unit.spacer1.gasId);
    final chamber1 = _chamberResistance(
      thicknessMm: unit.spacer1.thicknessMm,
      gas: gas1,
      emissivity1: unit.glass1.emissivity,
      emissivity2: unit.glass2.emissivity,
    );
    final camLabel1 = _chamberLabel(unit.spacer1, 1);
    layers.add(ThermalLayer(camLabel1, chamber1.thermalR));

    // 4. Стекло 2
    final rG2 = _glassResistance(unit.glass2);
    layers.add(ThermalLayer('${unit.glass2.label} (${(unit.glass2.thickness * 1000).toStringAsFixed(1)} мм)', rG2));

    // 5. (Для двухкамерного) Камера 2 + Стекло 3
    if (unit.type == GlazingUnitType.double_ &&
        unit.spacer2 != null &&
        unit.glass3 != null) {
      final gas2 = _getGas(unit.spacer2!.gasId);
      final chamber2 = _chamberResistance(
        thicknessMm: unit.spacer2!.thicknessMm,
        gas: gas2,
        emissivity1: unit.glass2.emissivity,
        emissivity2: unit.glass3!.emissivity,
      );
      final camLabel2 = _chamberLabel(unit.spacer2!, 2);
      layers.add(ThermalLayer(camLabel2, chamber2.thermalR));

      final rG3 = _glassResistance(unit.glass3!);
      layers.add(ThermalLayer('${unit.glass3!.label} (${(unit.glass3!.thickness * 1000).toStringAsFixed(1)} мм)', rG3));
    }
    // 6. Внутреннее граничное сопротивление
    const rSi = 1.0 / _hInternal;
    layers.add(const ThermalLayer('R_si (внутренняя поверхность)', rSi));

    // 7. Итог
    final r0 = layers.fold(0.0, (sum, l) => sum + l.rValue);
    final ug = 1.0 / r0;

    return ThermalResult(r0: r0, ug: ug, layers: layers);
  }

  // ── Приватные методы ───────────────────────────────────────────────────────

  /// Термическое сопротивление листа стекла: R = d / λ
  double _glassResistance(GlassType glass) {
    return glass.thickness / glass.lambda;
  }

  /// Расчёт термического сопротивления газовой камеры по EN 673, разделы 5–6.
  ///
  /// [thicknessMm]   — ширина камеры, мм
  /// [gas]           — теплофизические свойства газа
  /// [emissivity1]   — степень черноты внутренней поверхности стекла 1 (наружного)
  /// [emissivity2]   — степень черноты внутренней поверхности стекла 2 (внутреннего)
  ChamberResult _chamberResistance({
    required int thicknessMm,
    required GasType gas,
    required double emissivity1,
    required double emissivity2,
  }) {
    final s = thicknessMm / 1000.0; // перевод в метры

    // ── Конвективная составляющая h_c ────────────────────────────────────────
    // Число Грасгофа: Gr = g · β · ΔT · s³ · ρ² / η²
    // где β = 1/Tm (коэффициент теплового расширения идеального газа)
    const beta = 1.0 / _Tm; // 1/K
    final gr = 9.81 *
        beta *
        _deltaT *
        math.pow(s, 3) *
        math.pow(gas.rho, 2) /
        math.pow(gas.eta, 2);

    // Число Прандтля: Pr = η · cp / λ
    final pr = gas.eta * gas.cp / gas.lambda;

    // Число Нуссельта (корреляция EN 673 для вертикальной щели):
    // Nu = max(1, A · (Gr · Pr)^n)
    // Коэффициенты A = 0.035, n = 0.38 — для Gr·Pr в диапазоне EN 673
    const double a = 0.035;
    const double n = 0.38;
    final nu = math.max(1.0, a * math.pow(gr * pr, n));

    // h_c = Nu · λ / s
    final hc = nu * gas.lambda / s;

    // ── Радиационная составляющая h_r ─────────────────────────────────────
    // Приведённая степень черноты: ε* = 1 / (1/ε₁ + 1/ε₂ − 1)
    final eStar = 1.0 / (1.0 / emissivity1 + 1.0 / emissivity2 - 1.0);

    // h_r = 4 · σ · ε* · Tm³
    final hr = 4.0 * _sigma * eStar * math.pow(_Tm, 3);

    // ── Суммарный коэффициент и сопротивление ─────────────────────────────
    final hs = hc + hr;
    final rs = 1.0 / hs;

    return ChamberResult(
      hConvective: hc,
      hRadiative: hr,
      hTotal: hs,
      thermalR: rs,
    );
  }

  /// Получить объект газа по id, по умолчанию — воздух.
  GasType _getGas(String gasId) {
    return GasCatalog.findById(gasId) ?? GasCatalog.air;
  }

  /// Сформировать метку камеры для отображения.
  String _chamberLabel(SpacerConfig spacer, int index) {
    final gasName = _getGas(spacer.gasId).label;
    final frameNote = spacer.frameType == SpacerFrameType.warm
        ? ' · тёплая рамка'
        : '';
    return 'Камера $index: ${spacer.thicknessMm} мм · $gasName$frameNote';
  }
}