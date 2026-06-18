/// Модель стекла с теплотехническими характеристиками.
///
/// Параметры взяты из EN 673 и технических данных производителей.
/// [emissivity] — приведённая степень черноты поверхности (ε):
///   - обычное флоат-стекло: 0.89
///   - Low-E мягкое покрытие (ε ≈ 0.04): например, Pilkington K Glass, Guardian UniCoat
///   - Solar (твёрдое покрытие, ε ≈ 0.15): ограничивает солнечную нагрузку
class GlassType {
  final String id;
  final String label;        // краткое обозначение (для формулы)
  final String description;  // полное название
  final double thickness;    // толщина, м
  final double emissivity;   // коэффициент излучения ε (безразмерный)
  final double lambda;       // теплопроводность, Вт/(м·К)

  const GlassType({
    required this.id,
    required this.label,
    required this.description,
    required this.thickness,
    required this.emissivity,
    required this.lambda,
  });

  @override
  String toString() => label;
}

/// Каталог доступных типов стёкол.
class GlassCatalog {
  GlassCatalog._(); // приватный конструктор — только статические члены

  static const List<GlassType> all = [
    GlassType(
      id: '4',
      label: '4',
      description: '4 мм — флоат (обычное)',
      thickness: 0.004,
      emissivity: 0.89,
      lambda: 1.0,
    ),
    GlassType(
      id: '6',
      label: '6',
      description: '6 мм — флоат (обычное)',
      thickness: 0.006,
      emissivity: 0.89,
      lambda: 1.0,
    ),
    GlassType(
      id: '4i',
      label: '4i',
      description: '4i — Low-E мягкое покрытие (ε = 0.04)',
      thickness: 0.004,
      emissivity: 0.04,
      lambda: 1.0,
    ),
    GlassType(
      id: '6i',
      label: '6i',
      description: '6i — Low-E мягкое покрытие (ε = 0.04)',
      thickness: 0.006,
      emissivity: 0.04,
      lambda: 1.0,
    ),
    GlassType(
      id: '4Solar',
      label: '4Solar',
      description: '4 Solar — солнцезащитное покрытие (ε = 0.15)',
      thickness: 0.004,
      emissivity: 0.15,
      lambda: 1.0,
    ),
    GlassType(
      id: '6Solar',
      label: '6Solar',
      description: '6 Solar — солнцезащитное покрытие (ε = 0.15)',
      thickness: 0.006,
      emissivity: 0.15,
      lambda: 1.0,
    ),
    GlassType(
      id: '3.3.1',
      label: '3.3.1',
      description: '3.3.1 — триплекс (≈ 6.8 мм)',
      thickness: 0.0068,
      emissivity: 0.89,
      lambda: 0.95,
    ),
    GlassType(
      id: '3.3.1i',
      label: '3.3.1i',
      description: '3.3.1i — триплекс с Low-E (ε = 0.04)',
      thickness: 0.0068,
      emissivity: 0.04,
      lambda: 0.95,
    ),
    GlassType(
      id: '3.3.1Solar',
      label: '3.3.1Solar',
      description: '3.3.1 Solar — триплекс с солнцезащитой (ε = 0.15)',
      thickness: 0.0068,
      emissivity: 0.15,
      lambda: 0.95,
    ),
    GlassType(
      id: '4.4.1',
      label: '4.4.1',
      description: '4.4.1 — триплекс (≈ 9.5 мм)',
      thickness: 0.0095,
      emissivity: 0.89,
      lambda: 0.95,
    ),
    GlassType(
      id: '4.4.1i',
      label: '4.4.1i',
      description: '4.4.1i — триплекс с Low-E (ε = 0.04)',
      thickness: 0.0095,
      emissivity: 0.04,
      lambda: 0.95,
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