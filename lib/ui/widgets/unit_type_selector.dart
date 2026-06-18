import 'package:flutter/material.dart';
import '../../models/glazing_unit.dart';

/// Переключатель типа стеклопакета: однокамерный / двухкамерный.
class UnitTypeSelector extends StatelessWidget {
  final GlazingUnitType selected;
  final ValueChanged<GlazingUnitType> onChanged;

  const UnitTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<GlazingUnitType>(
      segments: const [
        ButtonSegment(
          value: GlazingUnitType.single,
          label: Text('Однокамерный'),
          icon: Icon(Icons.looks_one_outlined),
        ),
        ButtonSegment(
          value: GlazingUnitType.double_,
          label: Text('Двухкамерный'),
          icon: Icon(Icons.looks_two_outlined),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}