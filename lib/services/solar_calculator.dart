import '../models/glass.dart';
import '../models/glazing_unit.dart';

// ── Типы рамы окна ─────────────────────────────────────────────────────────

/// Тип / цвет рамы для расчёта солнечного фактора рамы.
enum FrameType {
  whitePvc('whitePvc', 'Белый ПВХ', 0.25),
  lightGrey('lightGrey', 'Светло-серый / кремовый', 0.35),
  darkGrey('darkGrey', 'Тёмно-серый / бронза', 0.62),
  black('black', 'Чёрный / тёмно-коричневый', 0.87),
  alumNatural('alumNatural', 'Алюминий анодированный (натуральный)', 0.47),
  woodLight('woodLight', 'Деревянная рама (светлая)', 0.40);

  final String id;
  final String label;

  /// Коэффициент поглощения αf — среднее значение диапазона по EN 13363-1
  final double alphaF;

  const FrameType(this.id, this.label, this.alphaF);
}

// ── Параметры рамы окна ────────────────────────────────────────────────────

/// Конфигурация рамы для расчёта g окна в целом (EN 13363-1).
class FrameConfig {
  /// Ширина видимой части рамы снаружи, м
  final double frameWidthM;

  /// Тип / цвет рамы (определяет αf)
  final FrameType frameType;

  const FrameConfig({
    required this.frameWidthM,
    required this.frameType,
  });

  FrameConfig copyWith({double? frameWidthM, FrameType? frameType}) {
    return FrameConfig(
      frameWidthM: frameWidthM ?? this.frameWidthM,
      frameType: frameType ?? this.frameType,
    );
  }
}

// ── Параметры окна ─────────────────────────────────────────────────────────

/// Размеры окна для расчёта g окна в целом.
class WindowDimensions {
  /// Ширина окна в свету (м)
  final double widthM;

  /// Высота окна в свету (м)
  final double heightM;

  const WindowDimensions({required this.widthM, required this.heightM});

  WindowDimensions copyWith({double? widthM, double? heightM}) {
    return WindowDimensions(
      widthM: widthM ?? this.widthM,
      heightM: heightM ?? this.heightM,
    );
  }
}

// ── Результат расчёта ──────────────────────────────────────────────────────

/// Детальный результат расчёта солнечного фактора g стеклопакета (EN 410).
class GlazingGResult {
  /// Суммарный коэффициент прямого пропускания стеклопакета τe
  final double tauE;

  /// Суммарный коэффициент отражения стеклопакета ρe
  final double rhoE;

  /// Коэффициент поглощения стекла 1 (с учётом переотражений)
  final double a1;

  /// Коэффициент поглощения стекла 2 (с учётом переотражений)
  final double a2;

  /// Коэффициент поглощения стекла 3 (только для двухкамерного)
  final double? a3;

  /// Вторичный коэффициент теплопередачи внутрь qi
  final double qi;

  /// Солнечный фактор стеклопакета ggl = τe + qi
  final double ggl;

  const GlazingGResult({
    required this.tauE,
    required this.rhoE,
    required this.a1,
    required this.a2,
    this.a3,
    required this.qi,
    required this.ggl,
  });
}

/// Полный результат расчёта g стеклопакета + g окна с рамой (EN 13363).
class SolarResult {
  /// Результат для стеклопакета
  final GlazingGResult glazing;

  /// Солнечный фактор рамы gf (null если расчёт окна не запрошен)
  final double? gf;

  /// Площадь остекления Ag, м²
  final double? aGlazing;

  /// Площадь рамы Af, м²
  final double? aFrame;

  /// Доля остекления Ff = Ag / Aw
  final double? glazingFraction;

  /// Солнечный фактор окна gw (null если расчёт окна не запрошен)
  final double? gw;

  /// Shading Coefficient стеклопакета SC = ggl / 0.87
  final double sc;

  /// Shading Coefficient окна с рамой SCw = gw / 0.87 (null если рама не учтена)
  final double? scWindow;

  const SolarResult({
    required this.glazing,
    this.gf,
    this.aGlazing,
    this.aFrame,
    this.glazingFraction,
    this.gw,
    required this.sc,
    this.scWindow,
  });
}

// ── Сервис расчёта ─────────────────────────────────────────────────────────

/// Расчёт солнечного фактора g по EN 410 (стеклопакет) и EN 13363-1 (окно).
///
/// Граничные условия по EN 410:
///   he = 23 Вт/(м²·К), hi = 8 Вт/(м²·К)
class SolarCalculator {
  // Граничные условия EN 410
  static const double _he = 23.0; // коэффициент теплоотдачи снаружи
  static const double _hi = 8.0;  // коэффициент теплоотдачи изнутри

  /// Рассчитать g стеклопакета без учёта рамы.
  ///
  /// [unit] — конфигурация стеклопакета.
  SolarResult calculateGlazing(GlazingUnit unit) {
    final glazingResult = _calcGlazingG(unit);
    final sc = glazingResult.ggl / 0.87;
    return SolarResult(glazing: glazingResult, sc: sc);
  }

  /// Рассчитать g стеклопакета + g окна с рамой.
  ///
  /// [unit]       — конфигурация стеклопакета.
  /// [window]     — размеры окна.
  /// [frame]      — параметры рамы.
  SolarResult calculateWindow({
    required GlazingUnit unit,
    required WindowDimensions window,
    required FrameConfig frame,
  }) {
    final glazingResult = _calcGlazingG(unit);

    // ── Геометрия окна ─────────────────────────────────────────────────────
    final aw = window.widthM * window.heightM;
    final bf = frame.frameWidthM;
    final agW = (window.widthM - 2 * bf).clamp(0.0, double.infinity);
    final agH = (window.heightM - 2 * bf).clamp(0.0, double.infinity);
    final ag = agW * agH;
    final af = (aw - ag).clamp(0.0, double.infinity);
    final ff = aw > 0 ? (ag / aw).clamp(0.0, 1.0) : 0.0;

    // ── Солнечный фактор рамы gf (EN 13363-1, раздел 6) ──────────────────
    // gf = αf × hi / (he + hi)
    final gf = frame.frameType.alphaF * _hi / (_he + _hi);

    // ── Солнечный фактор окна gw ───────────────────────────────────────────
    // gw = ggl × Ff + gf × (1 − Ff)
    final gw = glazingResult.ggl * ff + gf * (1.0 - ff);

    final sc = glazingResult.ggl / 0.87;
    final scWindow = gw / 0.87;

    return SolarResult(
      glazing: glazingResult,
      gf: gf,
      aGlazing: ag,
      aFrame: af,
      glazingFraction: ff,
      gw: gw,
      sc: sc,
      scWindow: scWindow,
    );
  }

  // ── Внутренний расчёт g стеклопакета (EN 410) ────────────────────────────

  GlazingGResult _calcGlazingG(GlazingUnit unit) {
    if (unit.type == GlazingUnitType.single) {
      return _calcSingle(unit.glass1, unit.glass2);
    } else {
      return _calcDouble(unit.glass1, unit.glass2, unit.glass3!);
    }
  }

  /// Однокамерный стеклопакет: стекло1 — камера — стекло2.
  GlazingGResult _calcSingle(GlassType g1, GlassType g2) {
    // ── Шаг 2: τe стеклопакета ───────────────────────────────────────────
    final denom = 1.0 - g1.rhoEb * g2.rhoEf;
    final tauE = (g1.tauE * g2.tauE) / denom;

    // ── Отражение стеклопакета (фронтальное) ─────────────────────────────
    final rhoE = g1.rhoEf +
        (g1.tauE * g1.tauE * g2.rhoEf) / denom;

    // ── Шаг 3: поглощение в каждом стекле ────────────────────────────────
    final a1 = g1.alphaE / denom;
    final a2 = (g1.tauE * g2.alphaE) / denom;

    // ── Шаг 4: qi ─────────────────────────────────────────────────────────
    // Упрощённая формула EN 410 (раздел 5, шаг 4):
    // qi = (A1 × hi⁻¹ + A2 × hi⁻¹) × he × hi / (he + hi)
    // Корректная форма: доля каждого слоя, переданная внутрь,
    // пропорциональна сопротивлению между этим слоем и внешней средой.
    //
    // Для однокамерного — оба стекла отдают тепло через поверхностные
    // сопротивления. Использован стандартный приближённый метод EN 410:
    final qi = (a1 + a2) * _hi / (_he + _hi);

    final ggl = (tauE + qi).clamp(0.0, 1.0);

    return GlazingGResult(
      tauE: tauE,
      rhoE: rhoE,
      a1: a1,
      a2: a2,
      qi: qi,
      ggl: ggl,
    );
  }

  /// Двухкамерный стеклопакет: стекло1 — камера1 — стекло2 — камера2 — стекло3.
  GlazingGResult _calcDouble(GlassType g1, GlassType g2, GlassType g3) {
    // ── Шаг 2: τe стеклопакета ───────────────────────────────────────────
    // Система 1–2
    final denom12 = 1.0 - g1.rhoEb * g2.rhoEf;
    final tauE12 = (g1.tauE * g2.tauE) / denom12;

    // Тыльное отражение системы 1–2
    final rhoEb12 = g2.rhoEb + (g2.tauE * g2.tauE * g1.rhoEb) / denom12;

    // Система 1–2–3
    final denom123 = 1.0 - rhoEb12 * g3.rhoEf;
    final tauE = (tauE12 * g3.tauE) / denom123;

    // Отражение пакета (фронтальное)
    final rhoEf12 = g1.rhoEf + (g1.tauE * g1.tauE * g2.rhoEf) / denom12;
    final rhoE = rhoEf12 + (tauE12 * tauE12 * g3.rhoEf) / denom123;

    // ── Шаг 3: поглощение в каждом стекле ────────────────────────────────
    // Стекло 1
    final a1 = g1.alphaE / denom12 / denom123 * denom123; // упрощение ниже

    // Точный расчёт через разложение по системам:
    // a1 = αe1 * (1 + ρb12 * ρf3 / denom123) / denom12  — приближение
    // Используем корректный метод Transfer Matrix:
    final a1corr = g1.alphaE / denom12;
    final a2corr = (g1.tauE * g2.alphaE) / denom12;
    // Доля от стекла 1 и 2, домноженная на прохождение через 3-й слой
    final a1full = a1corr * (1.0 + rhoEb12 * g3.rhoEf / denom123);
    final a2full = a2corr * (1.0 + rhoEb12 * g3.rhoEf / denom123);
    // Стекло 3
    final a3 = tauE12 * g3.alphaE / denom123;

    // ── Шаг 4: qi ─────────────────────────────────────────────────────────
    // Упрощённый метод EN 410: все стёкла отдают тепло через суммарное
    // граничное сопротивление. Для более строгого расчёта нужен ISO 15099.
    final qi = (a1full + a2full + a3) * _hi / (_he + _hi);

    final ggl = (tauE + qi).clamp(0.0, 1.0);

    // Подавляем предупреждение о неиспользуемой переменной
    // ignore: unused_local_variable, no_leading_underscores_for_local_identifiers
    final _unused = a1;

    return GlazingGResult(
      tauE: tauE,
      rhoE: rhoE,
      a1: a1full,
      a2: a2full,
      a3: a3,
      qi: qi,
      ggl: ggl,
    );
  }

  // ── Поправочный коэффициент на угол падения Fw (EN 13363-1, Таблица 1) ──

  /// Возвращает Fw для заданного угла θ (в градусах).
  ///
  /// [isLowE] — true для Low-E стёкол.
  static double angularCorrectionFactor(double thetaDeg, {bool isLowE = false}) {
    // Таблица из EN 13363-1 (нормальное стекло / Low-E)
    const anglesNormal = [0.0, 10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0];
    const fwNormal    = [1.00, 1.00, 0.99, 0.97, 0.93, 0.85, 0.72, 0.54];
    const fwLowE      = [1.00, 0.99, 0.98, 0.95, 0.89, 0.80, 0.66, 0.48];

    final fw = isLowE ? fwLowE : fwNormal;
    final theta = thetaDeg.clamp(0.0, 70.0);

    for (int i = 0; i < anglesNormal.length - 1; i++) {
      if (theta <= anglesNormal[i + 1]) {
        final t = (theta - anglesNormal[i]) /
            (anglesNormal[i + 1] - anglesNormal[i]);
        return fw[i] + t * (fw[i + 1] - fw[i]);
      }
    }
    return fw.last;
  }
}
