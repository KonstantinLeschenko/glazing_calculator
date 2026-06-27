/// Модель стекла с теплотехническими и оптическими характеристиками.
///
/// Теплотехнические параметры по EN 673.
/// Оптические параметры (τe, ρe_f, ρe_b) по EN 410 / EN ISO 9050:
///   - τe  — коэффициент прямого пропускания солнечного излучения
///   - ρe_f — коэффициент отражения (фронтальная сторона)
///   - ρe_b — коэффициент отражения (тыльная сторона)
///   αe вычисляется как 1 − τe − ρe_f
class GlassType {
  final String id;
  final String label;        // краткое обозначение (для формулы)
  final String description;  // полное название
  final double thickness;    // толщина, м
  final double emissivity;   // коэффициент излучения ε (безразмерный)
  final double lambda;       // теплопроводность, Вт/(м·К)

  // ── Оптические свойства (EN 410) ─────────────────────────────────────────
  /// Коэффициент прямого пропускания солнечного излучения (300–2500 нм)
  final double tauE;

  /// Коэффициент отражения солнечного излучения — фронтальная сторона
  final double rhoEf;

  /// Коэффициент отражения солнечного излучения — тыльная сторона
  final double rhoEb;

  /// Коэффициент поглощения: αe = 1 − τe − ρe_f
  double get alphaE => (1.0 - tauE - rhoEf).clamp(0.0, 1.0);

  const GlassType({
    required this.id,
    required this.label,
    required this.description,
    required this.thickness,
    required this.emissivity,
    required this.lambda,
    required this.tauE,
    required this.rhoEf,
    required this.rhoEb,
  });

  @override
  String toString() => label;
}

/// Каталог доступных типов стёкол.
///
/// Оптические данные — EN 410 / EN ISO 9050 / техлисты производителей
/// (таблица 8.3 методики расчёта солнечного фактора g).
class GlassCatalog {
  GlassCatalog._(); // приватный конструктор — только статические члены

  static const List<GlassType> all = [
    // ── Флоат-стёкла ────────────────────────────────────────────────────────
    GlassType(
      id: '4',
      label: '4',
      description: '4 мм — флоат (обычное)',
      thickness: 0.004,
      emissivity: 0.89,
      lambda: 1.0,
      tauE: 0.834,
      rhoEf: 0.074,
      rhoEb: 0.074,
    ),
    GlassType(
      id: '6',
      label: '6',
      description: '6 мм — флоат (обычное)',
      thickness: 0.006,
      emissivity: 0.89,
      lambda: 1.0,
      tauE: 0.788,
      rhoEf: 0.073,
      rhoEb: 0.073,
    ),

    // ── Low-E (мягкое покрытие, ε = 0.04) ───────────────────────────────────
    GlassType(
      id: '4i',
      label: '4i',
      description: '4i — Low-E мягкое покрытие (ε = 0.04)',
      thickness: 0.004,
      emissivity: 0.04,
      lambda: 1.0,
      tauE: 0.730,
      rhoEf: 0.116,
      rhoEb: 0.052,
    ),
    GlassType(
      id: '6i',
      label: '6i',
      description: '6i — Low-E мягкое покрытие (ε = 0.04)',
      thickness: 0.006,
      emissivity: 0.04,
      lambda: 1.0,
      tauE: 0.720,
      rhoEf: 0.108,
      rhoEb: 0.052,
    ),

    // ── Solar / солнцезащитные (твёрдое покрытие, ε = 0.15) ─────────────────
    GlassType(
      id: '4Solar',
      label: '4Solar',
      description: '4 Solar — солнцезащитное покрытие (ε = 0.15)',
      thickness: 0.004,
      emissivity: 0.15,
      lambda: 1.0,
      tauE: 0.420,
      rhoEf: 0.330,
      rhoEb: 0.330,
    ),
    GlassType(
      id: '6Solar',
      label: '6Solar',
      description: '6 Solar — солнцезащитное покрытие (ε = 0.15)',
      thickness: 0.006,
      emissivity: 0.15,
      lambda: 1.0,
      tauE: 0.380,
      rhoEf: 0.320,
      rhoEb: 0.320,
    ),

    // ── Тонированные ────────────────────────────────────────────────────────
    GlassType(
      id: '6bronze',
      label: '6бронза',
      description: '6 мм — бронзовое тонированное',
      thickness: 0.006,
      emissivity: 0.89,
      lambda: 1.0,
      tauE: 0.295,
      rhoEf: 0.065,
      rhoEb: 0.065,
    ),
    GlassType(
      id: '6grey',
      label: '6серое',
      description: '6 мм — серое тонированное',
      thickness: 0.006,
      emissivity: 0.89,
      lambda: 1.0,
      tauE: 0.250,
      rhoEf: 0.062,
      rhoEb: 0.062,
    ),

    // ── Триплекс ────────────────────────────────────────────────────────────
    GlassType(
      id: '3.3.1',
      label: '3.3.1',
      description: '3.3.1 — триплекс (≈ 6.8 мм)',
      thickness: 0.0068,
      emissivity: 0.89,
      lambda: 0.95,
      tauE: 0.758,
      rhoEf: 0.075,
      rhoEb: 0.075,
    ),
    GlassType(
      id: '3.3.1i',
      label: '3.3.1i',
      description: '3.3.1i — триплекс с Low-E (ε = 0.04)',
      thickness: 0.0068,
      emissivity: 0.04,
      lambda: 0.95,
      tauE: 0.660,
      rhoEf: 0.110,
      rhoEb: 0.050,
    ),
    GlassType(
      id: '3.3.1Solar',
      label: '3.3.1Solar',
      description: '3.3.1 Solar — триплекс с солнцезащитой (ε = 0.15)',
      thickness: 0.0068,
      emissivity: 0.15,
      lambda: 0.95,
      tauE: 0.380,
      rhoEf: 0.310,
      rhoEb: 0.310,
    ),
    GlassType(
      id: '4.4.1',
      label: '4.4.1',
      description: '4.4.1 — триплекс (≈ 9.5 мм)',
      thickness: 0.0095,
      emissivity: 0.89,
      lambda: 0.95,
      tauE: 0.740,
      rhoEf: 0.075,
      rhoEb: 0.075,
    ),
    GlassType(
      id: '4.4.1i',
      label: '4.4.1i',
      description: '4.4.1i — триплекс с Low-E (ε = 0.04)',
      thickness: 0.0095,
      emissivity: 0.04,
      lambda: 0.95,
      tauE: 0.640,
      rhoEf: 0.108,
      rhoEb: 0.050,
    ),
  ];

  /// Найти тип стекла по id.
  static GlassType? findById(String id) {
    try {
      return all.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}
