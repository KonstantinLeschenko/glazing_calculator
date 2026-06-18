// Тип дистанционного профиля (рамки) стеклопакета.
///
/// Алюминиевая рамка — классическая, высокотеплопроводная (холодный край).
/// Пластиковая/теплоизолирующая рамка ("тёплый край") снижает теплопотери
/// по периметру, но не влияет на R₀ центральной зоны стеклопакета.
enum SpacerFrameType {
  aluminium('alu', 'Алюминиевая'),
  warm('pdn', 'Тёплая (пластик/сталь)');

  final String id;
  final String label;

  const SpacerFrameType(this.id, this.label);
}

/// Параметры одной газовой камеры стеклопакета.
class SpacerConfig {
  /// Ширина дистанционного профиля (толщина воздушного зазора), мм.
  final int thicknessMm;

  /// Тип газа-наполнителя.
  final String gasId;

  /// Тип дистанционного профиля.
  final SpacerFrameType frameType;

  const SpacerConfig({
    required this.thicknessMm,
    required this.gasId,
    this.frameType = SpacerFrameType.aluminium,
  });

  /// Доступные размеры дистанционного профиля (мм).
  static const List<int> availableThicknesses = [
    8, 10, 12, 14, 16, 18, 20, 22, 24,
  ];

  SpacerConfig copyWith({
    int? thicknessMm,
    String? gasId,
    SpacerFrameType? frameType,
  }) {
    return SpacerConfig(
      thicknessMm: thicknessMm ?? this.thicknessMm,
      gasId: gasId ?? this.gasId,
      frameType: frameType ?? this.frameType,
    );
  }
}