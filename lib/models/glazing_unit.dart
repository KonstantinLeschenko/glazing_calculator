import 'glass.dart';
import 'spacer.dart';

/// Тип стеклопакета по числу камер.
enum GlazingUnitType {
  single('Однокамерный', 1),
  double_('Двухкамерный', 2);

  final String label;
  final int chamberCount;

  const GlazingUnitType(this.label, this.chamberCount);
}

/// Конфигурация стеклопакета: набор стёкол и камер.
///
/// Однокамерный: [glass1] - [spacer1] - [glass2]
/// Двухкамерный: [glass1] - [spacer1] - [glass2] - [spacer2] - [glass3]
class GlazingUnit {
  final GlazingUnitType type;
  final GlassType glass1;
  final SpacerConfig spacer1;
  final GlassType glass2;
  final SpacerConfig? spacer2;  // только для двухкамерного
  final GlassType? glass3;      // только для двухкамерного

  const GlazingUnit.single({
    required this.glass1,
    required this.spacer1,
    required this.glass2,
  })  : type = GlazingUnitType.single,
        spacer2 = null,
        glass3 = null;

  const GlazingUnit.double_({
    required this.glass1,
    required this.spacer1,
    required this.glass2,
    required SpacerConfig this.spacer2,
    required GlassType this.glass3,
  }) : type = GlazingUnitType.double_;

  /// Строка формулы стеклопакета (например: «4 - 16 - 4i» или «4 - 16 Ar - 4i - 16 - 4»).
  String get formula {
    String gasLabel(SpacerConfig s) =>
        s.gasId == 'air' ? '' : ' Ar';
    final buf = StringBuffer()
      ..write(glass1.label)
      ..write(' — ')
      ..write(spacer1.thicknessMm)
      ..write(gasLabel(spacer1))
      ..write(' — ')
      ..write(glass2.label);
    if (type == GlazingUnitType.double_ && spacer2 != null && glass3 != null) {
      buf
        ..write(' — ')
        ..write(spacer2!.thicknessMm)
        ..write(gasLabel(spacer2!))
        ..write(' — ')
        ..write(glass3!.label);
    }
    return buf.toString();
  }
}