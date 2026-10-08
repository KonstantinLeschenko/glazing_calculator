import 'dart:math' as math;
import '../models/gas.dart';
import '../models/glass.dart';
import '../models/glazing_unit.dart';
import '../models/spacer.dart';

/// Результат оценки звукоизоляции стеклопакета.
class SoundResult {
  /// Расчётная оценка индекса звукоизоляции Rw, дБ
  final double rw;

  /// Детальная разбивка расчёта для отображения в UI
  final List<SoundLayer> layers;

  const SoundResult({required this.rw, required this.layers});
}

/// Одна строка разбивки расчёта звукоизоляции.
class SoundLayer {
  final String label;
  final String value;

  const SoundLayer(this.label, this.value);
}

/// Сервис оценки звукоизоляции (индекса Rw) стеклопакета.
///
/// В отличие от EN 673 (теплопередача) и EN 410 (солнечный фактор), EN 12758
/// не даёт замкнутой расчётной формулы для Rw — стандарт основан на подборе
/// и интерполяции протестированных в лаборатории конфигураций (Annex B).
///
/// Здесь применена инженерная оценочная модель на основе физики резонанса
/// «масса-воздух-масса» (используется в ISO 12354-1 / модель Sharp):
///
///  1. Rw одиночного листа — эмпирическая регрессия по справочным данным
///     производителей листового стекла: Rw ≈ 13.5·lg(d, мм) + 21.
///  2. Rw пакета оценивается через закон массы для суммарной толщины стёкол
///     (эквивалентный монолитный лист), скорректированный штрафами за:
///       - резонанс «масса-воздух-масса» камеры (провал около 150–250 Гц —
///         наиболее весомого для индекса Rw диапазона);
///       - совпадение критических (коинциденс) частот стёкол одинаковой
///         толщины — асимметричные пакеты всегда дают более высокий Rw,
///         так как провалы разных стёкол приходятся на разные частоты.
///  3. Ламинированные стёкла (триплекс) получают бонус за демпфирование
///     резонанса плёнкой PVB.
///
/// ВАЖНО: результат — расчётная ОЦЕНКА для сравнения вариантов между собой,
/// а не сертифицированное значение. Официальный Rw/C/Ctr подтверждается
/// только лабораторными испытаниями по EN ISO 10140 с классификацией
/// по EN 12758.
class SoundCalculator {
  // ── Физические константы ────────────────────────────────────────────────
  /// Плотность стекла, кг/м³
  static const double _glassDensity = 2500.0;

  /// Атмосферное давление, Па
  static const double _atmPressure = 101325.0;

  // ── Коэффициенты эмпирической модели ────────────────────────────────────
  static const double _regressionA = 13.5;
  static const double _regressionB = 21.0;
  static const double _laminatedBonusDb = 2.0;

  static const double _mamPenaltyPeakDb = 3.0;
  static const double _mamPeakFrequencyHz = 180.0;
  static const double _mamWidthOctaves = 0.7;

  static const double _coincPenaltyPeakDb = 2.5;
  static const double _coincRatioCutoff = 0.3;

  /// Рассчитывает оценку Rw стеклопакета по его конфигурации.
  SoundResult calculate(GlazingUnit unit) {
    final panes = <GlassType>[unit.glass1, unit.glass2];
    final chambers = <SpacerConfig>[unit.spacer1];
    if (unit.type == GlazingUnitType.double_ &&
        unit.glass3 != null &&
        unit.spacer2 != null) {
      panes.add(unit.glass3!);
      chambers.add(unit.spacer2!);
    }

    final layers = <SoundLayer>[];

    // ── Листы стекла: масса, одиночный Rw, критическая частота ────────────
    final masses = <double>[];
    final criticalFreqs = <double>[];
    double totalThicknessMm = 0;
    double laminatedBonusSum = 0;

    for (var i = 0; i < panes.length; i++) {
      final g = panes[i];
      final thicknessMm = g.thickness * 1000;
      final mass = _glassDensity * g.thickness;
      final fc = 12000.0 / thicknessMm;
      final laminated = _isLaminated(g);

      masses.add(mass);
      criticalFreqs.add(fc);
      totalThicknessMm += thicknessMm;
      if (laminated) laminatedBonusSum += _laminatedBonusDb;

      layers.add(SoundLayer(
        'Стекло ${i + 1} (${g.label}, ${thicknessMm.toStringAsFixed(1)} мм)',
        '${mass.toStringAsFixed(1)} кг/м² · Rw(одиночн.) ≈ '
            '${_paneRw(thicknessMm, laminated).toStringAsFixed(1)} дБ',
      ));
    }

    // ── Камеры: резонансная частота масса-воздух-масса ─────────────────────
    double worstMamPenalty = 0;
    for (var i = 0; i < chambers.length; i++) {
      final spacer = chambers[i];
      final gas = GasCatalog.findById(spacer.gasId) ?? GasCatalog.air;
      final gamma = _gammaForGas(spacer.gasId);
      final gapM = spacer.thicknessMm / 1000.0;
      final f0 = _resonanceFrequency(
        m1: masses[i],
        m2: masses[i + 1],
        gapM: gapM,
        gamma: gamma,
      );
      final penalty = _mamPenalty(f0);
      worstMamPenalty = math.max(worstMamPenalty, penalty);

      layers.add(SoundLayer(
        'Камера ${i + 1} (${spacer.thicknessMm} мм · ${gas.label})',
        'f₀ ≈ ${f0.toStringAsFixed(0)} Гц',
      ));
    }

    // ── Наименьшее расхождение критических частот (худшая пара стёкол) ────
    double worstCoincRatio = double.infinity;
    for (var i = 0; i < criticalFreqs.length; i++) {
      for (var j = i + 1; j < criticalFreqs.length; j++) {
        final fi = criticalFreqs[i];
        final fj = criticalFreqs[j];
        final ratio = (fi - fj).abs() / math.max(fi, fj);
        worstCoincRatio = math.min(worstCoincRatio, ratio);
      }
    }
    final coincPenalty = _coincPenalty(worstCoincRatio);

    // ── Итоговая оценка ─────────────────────────────────────────────────────
    final massLawBaseline =
        _regressionA * _log10(totalThicknessMm) + _regressionB;
    final baseline = massLawBaseline + laminatedBonusSum;
    final rw = baseline - worstMamPenalty - coincPenalty;

    layers.add(SoundLayer(
      'База (закон массы, Σd = ${totalThicknessMm.toStringAsFixed(1)} мм)'
      '${laminatedBonusSum > 0 ? ' + ламинация' : ''}',
      '${baseline.toStringAsFixed(1)} дБ',
    ));
    layers.add(SoundLayer(
      'Штраф за резонанс масса-воздух-масса',
      '−${worstMamPenalty.toStringAsFixed(1)} дБ',
    ));
    layers.add(SoundLayer(
      'Штраф за совпадение критических частот',
      '−${coincPenalty.toStringAsFixed(1)} дБ',
    ));

    return SoundResult(rw: rw, layers: layers);
  }

  // ── Приватные методы ─────────────────────────────────────────────────────

  double _log10(double x) => math.log(x) / math.ln10;

  double _paneRw(double thicknessMm, bool laminated) {
    final base = _regressionA * _log10(thicknessMm) + _regressionB;
    return base + (laminated ? _laminatedBonusDb : 0.0);
  }

  /// Ламинированные (триплекс) стёкла в каталоге имеют составной id вида
  /// «3.3.1», «4.4.1» и т.п. — наличие точки однозначно их выделяет.
  bool _isLaminated(GlassType glass) => glass.id.contains('.');

  double _gammaForGas(String gasId) => gasId == 'ar90' ? 1.67 : 1.4;

  /// Резонансная частота «масса-воздух-масса» камеры стеклопакета:
  /// f0 = (1/2π) · √[ (γ·p₀/d) · (1/m₁ + 1/m₂) ],
  /// где γ·p₀ — адиабатическая жёсткость газа (не зависит от его плотности).
  double _resonanceFrequency({
    required double m1,
    required double m2,
    required double gapM,
    required double gamma,
  }) {
    final stiffness = gamma * _atmPressure;
    final value = (stiffness / gapM) * (1.0 / m1 + 1.0 / m2);
    return (1.0 / (2 * math.pi)) * math.sqrt(value);
  }

  /// Штраф за попадание резонанса масса-воздух-масса в наиболее весомый для
  /// индекса Rw диапазон (~150–250 Гц); логнормальный профиль по октавам.
  double _mamPenalty(double f0) {
    final octaves = math.log(f0 / _mamPeakFrequencyHz) / math.ln2;
    final exponent =
        -(octaves * octaves) / (2 * _mamWidthOctaves * _mamWidthOctaves);
    return _mamPenaltyPeakDb * math.exp(exponent);
  }

  /// Штраф за совпадение критических (коинциденс) частот стёкол одинаковой
  /// толщины; линейно спадает до нуля при относительном расхождении ≥ 30%.
  double _coincPenalty(double ratio) {
    if (ratio.isInfinite) return 0.0;
    final factor = (1.0 - (ratio / _coincRatioCutoff)).clamp(0.0, 1.0);
    return _coincPenaltyPeakDb * factor;
  }
}
