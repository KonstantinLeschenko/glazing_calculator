import 'package:flutter/material.dart';

/// Energy efficiency label widget with Invierno/Verano scales.
class EnergyLabelCard extends StatelessWidget {
  /// Thermal transmittance Ug (W/m²·K) to determine winter class.
  final double ug;

  /// Solar factor ggl value (0–1) to determine summer rating.
  final double ggl;

  const EnergyLabelCard({
    super.key,
    this.ug = 1.0,
    this.ggl = 0.4,
  });

  /// Returns winter class (A–G) based on Ug value.
  static String classFromUg(double ug) {
    if (ug <= 1.2) return 'A';
    if (ug <= 1.4) return 'B';
    if (ug <= 1.8) return 'C';
    if (ug <= 2.0) return 'D';
    if (ug <= 2.5) return 'E';
    if (ug <= 3.0) return 'F';
    return 'G';
  }

  /// Returns number of stars based on ggl value:
  ///   ≤ 0.4 → 3 stars
  ///   > 0.4 and ≤ 0.6 → 2 stars
  ///   > 0.6 → 1 star
  static int starsFromGgl(double ggl) {
    if (ggl <= 0.4) return 3;
    if (ggl <= 0.6) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final winterClass = classFromUg(ug);
    final summerStars = starsFromGgl(ggl);
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 380,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left column: Invierno (Winter) scale — fixed width ──
              const SizedBox(width: 80, child: _InviernoColumn()),
              const SizedBox(width: 8),
              // ── Center column: current selections — takes remaining space ──
              Expanded(
                child: _CenterColumn(
                  winterClass: winterClass,
                  summerStars: summerStars,
                ),
              ),
              const SizedBox(width: 8),
              // ── Right column: Verano (Summer) scale — fixed width ──
              const SizedBox(width: 80, child: _VeranoColumn()),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Arrow CustomClipper
// ═══════════════════════════════════════════════════════════════════

/// Clips a rectangle into an arrow shape.
///
/// When [pointingLeft] is `false`, the arrow tip is at the right edge
/// (peak at `x = width`). When `true`, the tip is at the left edge
/// (peak at `x = 0`).
class _ArrowClipper extends CustomClipper<Path> {
  final bool pointingLeft;
  final double arrowDepth;

  const _ArrowClipper({
    this.pointingLeft = false,
    this.arrowDepth = 12,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    if (pointingLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(arrowDepth, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(arrowDepth, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width - arrowDepth, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - arrowDepth, size.height);
      path.lineTo(0, size.height);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ArrowClipper oldClipper) {
    return oldClipper.pointingLeft != pointingLeft ||
        oldClipper.arrowDepth != arrowDepth;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Single arrow widget
// ═══════════════════════════════════════════════════════════════════

/// An individual energy arrow with clip-path, gradient, and centered child.
class _EnergyArrow extends StatelessWidget {
  final bool pointingLeft;
  final Color color;
  final Widget child;
  final double height;

  const _EnergyArrow({
    required this.pointingLeft,
    required this.color,
    required this.child,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _ArrowClipper(
        pointingLeft: pointingLeft,
        arrowDepth: 12,
      ),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, _darken(color, 0.15)],
            begin:
                pointingLeft ? Alignment.centerRight : Alignment.centerLeft,
            end: pointingLeft ? Alignment.centerLeft : Alignment.centerRight,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  Color _darken(Color c, double amount) {
    return Color.fromRGBO(
      (c.red * (1 - amount)).round().clamp(0, 255),
      (c.green * (1 - amount)).round().clamp(0, 255),
      (c.blue * (1 - amount)).round().clamp(0, 255),
      1,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Winter column (Invierno) — green → red, letters A–G
// ═══════════════════════════════════════════════════════════════════

const List<Color> _winterColors = [
  Color(0xFF0F6E56), // A — dark green
  Color(0xFF2E8B57), // B — green
  Color(0xFF6B8E23), // C — olive
  Color(0xFFDAA520), // D — goldenrod
  Color(0xFFD2691E), // E — dark orange
  Color(0xFFCD5C5C), // F — indian red
  Color(0xFFB22222), // G — firebrick
];

const _winterLabels = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

class _InviernoColumn extends StatelessWidget {
  const _InviernoColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          'Invierno',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          'Más eficiente',
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        ...List.generate(
          7,
          (i) => _EnergyArrow(
            pointingLeft: false,
            color: _winterColors[i],
            child: Text(
              _winterLabels[i],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        Text(
          'Menos eficiente',
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Summer column (Verano) — dark blue → light blue, 1–3 stars
// ═══════════════════════════════════════════════════════════════════

const List<Color> _summerColors = [
  Color(0xFF0A2F5A), // 1 star — darkest blue
  Color(0xFF1A5276), // 2 stars — medium blue
  Color(0xFF5DADE2), // 3 stars — light blue
];

class _VeranoColumn extends StatelessWidget {
  const _VeranoColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          'Verano',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          'Más eficiente',
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        ...List.generate(
          3,
          (i) => _EnergyArrow(
            pointingLeft: true,
            color: _summerColors[i],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                i + 1,
                (_) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1),
                  child: Icon(Icons.star, color: Colors.white, size: 12),
                ),
              ),
            ),
          ),
        ),
        Text(
          'Menos eficiente',
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Center area — two columns: winter class (left) & summer rating (right)
// ═══════════════════════════════════════════════════════════════════

class _CenterColumn extends StatelessWidget {
  final String winterClass;
  final int summerStars;

  const _CenterColumn({
    required this.winterClass,
    required this.summerStars,
  });

  int _classIndex() {
    final idx = _winterLabels.indexOf(winterClass);
    return idx >= 0 ? idx : 0;
  }

  int _starIndex() {
    return summerStars.clamp(1, 3) - 1;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Left half: winter class arrow aligned with Invierno rows ──
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // spacer for title
              const SizedBox.shrink(),
              // spacer for "Más eficiente"
              const SizedBox.shrink(),
              // 7 rows matching Invierno letters — only selected one shows arrow
              ...List.generate(
                7,
                (i) {
                  if (i == _classIndex()) {
                    return _EnergyArrow(
                      pointingLeft: true,
                      color: _winterColors[i],
                      height: 36,
                      child: Text(
                        winterClass,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox(height: 36);
                  }
                },
              ),
              // spacer for "Menos eficiente"
              const SizedBox.shrink(),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // ── Right half: summer rating arrow aligned with Verano rows ──
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // spacer for title
              const SizedBox.shrink(),
              // spacer for "Más eficiente"
              const SizedBox.shrink(),
              // 3 rows matching Verano stars — only selected one shows arrow
              ...List.generate(
                3,
                (i) {
                  if (i == _starIndex()) {
                    return _EnergyArrow(
                      pointingLeft: false,
                      color: _summerColors[i],
                      height: 36,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          summerStars,
                          (_) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(Icons.star, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox(height: 36);
                  }
                },
              ),
              // spacer for "Menos eficiente"
              const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}