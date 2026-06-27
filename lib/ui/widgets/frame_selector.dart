import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/solar_calculator.dart';

/// Виджет выбора параметров оконной рамы и размеров окна
/// для расчёта солнечного фактора g окна в целом (EN 13363-1).
class FrameSelector extends StatefulWidget {
  final FrameConfig frameConfig;
  final WindowDimensions windowDimensions;
  final ValueChanged<FrameConfig> onFrameChanged;
  final ValueChanged<WindowDimensions> onWindowChanged;

  const FrameSelector({
    super.key,
    required this.frameConfig,
    required this.windowDimensions,
    required this.onFrameChanged,
    required this.onWindowChanged,
  });

  @override
  State<FrameSelector> createState() => _FrameSelectorState();
}

class _FrameSelectorState extends State<FrameSelector> {
  late TextEditingController _widthCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _frameWidthCtrl;

  @override
  void initState() {
    super.initState();
    _widthCtrl = TextEditingController(
        text: (widget.windowDimensions.widthM * 1000).round().toString());
    _heightCtrl = TextEditingController(
        text: (widget.windowDimensions.heightM * 1000).round().toString());
    _frameWidthCtrl = TextEditingController(
        text: (widget.frameConfig.frameWidthM * 1000).round().toString());
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _frameWidthCtrl.dispose();
    super.dispose();
  }

  void _onWindowDimChanged() {
    final w = double.tryParse(_widthCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    if (w != null && h != null && w > 0 && h > 0) {
      widget.onWindowChanged(WindowDimensions(
        widthM: w / 1000.0,
        heightM: h / 1000.0,
      ));
    }
  }

  void _onFrameWidthChanged() {
    final fw = double.tryParse(_frameWidthCtrl.text);
    if (fw != null && fw > 0) {
      widget.onFrameChanged(
          widget.frameConfig.copyWith(frameWidthM: fw / 1000.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Заголовок ─────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.window_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Параметры окна (для расчёта gw)',
                  style: tt.titleSmall?.copyWith(color: cs.primary),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Размеры окна ───────────────────────────────────────────────
            Text('Размеры окна в свету',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _mmField(
                    context: context,
                    label: 'Ширина, мм',
                    controller: _widthCtrl,
                    onChanged: (_) => _onWindowDimChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _mmField(
                    context: context,
                    label: 'Высота, мм',
                    controller: _heightCtrl,
                    onChanged: (_) => _onWindowDimChanged(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Ширина рамы ────────────────────────────────────────────────
            Text('Ширина рамы (видимая снаружи)',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            _mmField(
              context: context,
              label: 'Ширина рамы, мм',
              controller: _frameWidthCtrl,
              onChanged: (_) => _onFrameWidthChanged(),
            ),

            const SizedBox(height: 12),

            // ── Тип рамы ───────────────────────────────────────────────────
            Text('Тип / цвет рамы',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            DropdownButtonFormField<FrameType>(
              value: widget.frameConfig.frameType,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.palette_outlined, size: 20),
              ),
              items: FrameType.values.map((ft) {
                return DropdownMenuItem(
                  value: ft,
                  child: Text(ft.label, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  widget.onFrameChanged(widget.frameConfig.copyWith(frameType: v));
                }
              },
            ),

            // Подсказка: αf выбранного типа рамы
            const SizedBox(height: 6),
            Row(
              children: [
                _chip(context,
                    'αf = ${widget.frameConfig.frameType.alphaF.toStringAsFixed(2)}'),
                const SizedBox(width: 6),
                _chip(context,
                    'gf ≈ ${(widget.frameConfig.frameType.alphaF * 8 / 31).toStringAsFixed(3)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mmField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'мм',
      ),
      onChanged: onChanged,
    );
  }

  Widget _chip(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSecondaryContainer,
            ),
      ),
    );
  }
}
