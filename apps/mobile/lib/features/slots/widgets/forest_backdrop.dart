import 'dart:math';

import 'package:flutter/material.dart';

/// Full-bleed forest atmosphere behind the slot machine.
class ForestBackdrop extends StatefulWidget {
  const ForestBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<ForestBackdrop> createState() => _ForestBackdropState();
}

class _ForestBackdropState extends State<ForestBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(
                  const Color(0xFF0A1F14),
                  const Color(0xFF123322),
                  _pulse.value,
                )!,
                const Color(0xFF071018),
                const Color(0xFF140A1C),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _ForestPainter(twinkle: _pulse.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _ForestPainter extends CustomPainter {
  _ForestPainter({required this.twinkle});

  final double twinkle;

  @override
  void paint(Canvas canvas, Size size) {
    final ground = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1B5E20).withValues(alpha: 0.0),
          const Color(0xFF1B5E20).withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45),
      ground,
    );

    final trunk = Paint()..color = const Color(0xFF3E2723).withValues(alpha: 0.55);
    final foliage = Paint()..color = const Color(0xFF2E7D32).withValues(alpha: 0.4);

    void tree(double x, double baseY, double scale) {
      final trunkW = 10 * scale;
      final trunkH = 70 * scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, baseY - trunkH / 2),
            width: trunkW,
            height: trunkH,
          ),
          const Radius.circular(3),
        ),
        trunk,
      );
      canvas.drawCircle(Offset(x, baseY - trunkH), 28 * scale, foliage);
      canvas.drawCircle(
        Offset(x - 16 * scale, baseY - trunkH + 10 * scale),
        18 * scale,
        foliage,
      );
      canvas.drawCircle(
        Offset(x + 16 * scale, baseY - trunkH + 10 * scale),
        18 * scale,
        foliage,
      );
    }

    tree(size.width * 0.12, size.height * 0.78, 1.1);
    tree(size.width * 0.88, size.height * 0.74, 1.0);
    tree(size.width * 0.22, size.height * 0.9, 0.7);
    tree(size.width * 0.78, size.height * 0.92, 0.75);

    // Soft fireflies
    final glow = Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.15 + 0.2 * twinkle);
    final rng = Random(7);
    for (var i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.7;
      canvas.drawCircle(Offset(x, y), 1.5 + twinkle * 1.5, glow);
    }

    // Vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.55),
        ],
        radius: 1.05,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _ForestPainter oldDelegate) =>
      oldDelegate.twinkle != twinkle;
}
