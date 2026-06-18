/// Теплофизические свойства газа-наполнителя камеры стеклопакета.
///
/// Все значения приведены при расчётной температуре Tm = 283.15 K (10°C)
/// по EN 673, таблица B.1.
class GasType {
  final String id;
  final String label;
  final double lambda;  // теплопроводность, Вт/(м·К)
  final double eta;     // динамическая вязкость, Па·с
  final double rho;     // плотность, кг/м³
  final double cp;      // удельная теплоёмкость, Дж/(кг·К)

  const GasType({
    required this.id,
    required this.label,
    required this.lambda,
    required this.eta,
    required this.rho,
    required this.cp,
  });

  @override
  String toString() => label;
}

/// Каталог доступных газов-наполнителей.
class GasCatalog {
  GasCatalog._();

  static const GasType air = GasType(
    id: 'air',
    label: 'Воздух',
    lambda: 0.02440,
    eta: 1.733e-5,
    rho: 1.189,
    cp: 1006.1,
  );

  static const GasType argon90 = GasType(
    id: 'ar90',
    label: 'Аргон 90%',
    lambda: 0.01766,
    eta: 2.117e-5,
    rho: 1.623,
    cp: 519.0,
  );

  static const List<GasType> all = [air, argon90];

  static GasType? findById(String id) {
    try {
      return all.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}