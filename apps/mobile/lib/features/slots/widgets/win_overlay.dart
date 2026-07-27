import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme.dart';

class WinOverlay extends StatelessWidget {
  const WinOverlay({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: AppTheme.accentGold,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 12),
              Shadow(color: Color(0xFFFFD54F), blurRadius: 24),
            ],
          ),
        )
            .animate(key: ValueKey(text))
            .scale(begin: const Offset(0.6, 0.6), end: const Offset(1.1, 1.1), duration: 280.ms)
            .then()
            .scale(end: const Offset(1, 1), duration: 160.ms)
            .fadeIn(duration: 120.ms)
            .then(delay: 700.ms)
            .fadeOut(duration: 350.ms),
      ),
    );
  }
}
