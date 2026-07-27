import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class SlotMachineFrame extends StatelessWidget {
  const SlotMachineFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6D4C41),
            Color(0xFF3E2723),
            Color(0xFF5D4037),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
        border: Border.all(color: const Color(0xFFFFE082).withValues(alpha: 0.35), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0A121A),
          border: Border.all(color: const Color(0xFF1B2838), width: 2),
        ),
        clipBehavior: Clip.hardEdge,
        child: child,
      ),
    );
  }
}

class MultiplierLegend extends StatelessWidget {
  const MultiplierLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const tiers = [
      (_TierColors(Color(0xFFB87333), Color(0xFFFFCC80)), '0.2–4x'),
      (_TierColors(Color(0xFF90A4AE), Color(0xFFECEFF1)), '5–10x'),
      (_TierColors(Color(0xFFFFB300), Color(0xFFFFF59D)), '20–50x'),
      (_TierColors(Color(0xFF29B6F6), Color(0xFFB3E5FC)), '100–500x'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        children: [
          for (final tier in tiers)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border.all(color: tier.$1.outer.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [tier.$1.inner, tier.$1.outer],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tier.$1.outer.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.$2,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TierColors {
  const _TierColors(this.outer, this.inner);
  final Color outer;
  final Color inner;
}
