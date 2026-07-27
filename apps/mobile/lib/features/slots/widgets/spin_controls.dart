import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';

class SpinControls extends StatelessWidget {
  const SpinControls({
    super.key,
    required this.balance,
    required this.bet,
    required this.spinning,
    required this.canDecreaseBet,
    required this.canIncreaseBet,
    required this.onDecreaseBet,
    required this.onIncreaseBet,
    required this.onSpin,
  });

  final int balance;
  final int bet;
  final bool spinning;
  final bool canDecreaseBet;
  final bool canIncreaseBet;
  final VoidCallback onDecreaseBet;
  final VoidCallback onIncreaseBet;
  final VoidCallback onSpin;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'es');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        border: Border(
          top: BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          _StatBlock(label: 'SALDO', value: formatter.format(balance)),
          const Spacer(),
          IconButton(
            onPressed: spinning || !canDecreaseBet ? null : onDecreaseBet,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppTheme.textPrimary,
          ),
          _StatBlock(label: 'APUESTA', value: formatter.format(bet), align: TextAlign.center),
          IconButton(
            onPressed: spinning || !canIncreaseBet ? null : onIncreaseBet,
            icon: const Icon(Icons.add_circle_outline),
            color: AppTheme.textPrimary,
          ),
          const SizedBox(width: 8),
          _SpinButton(spinning: spinning, onSpin: onSpin),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    this.align = TextAlign.left,
  });

  final String label;
  final String value;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, letterSpacing: 0.8),
        ),
        Text(
          value,
          textAlign: align,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

class _SpinButton extends StatefulWidget {
  const _SpinButton({required this.spinning, required this.onSpin});

  final bool spinning;
  final VoidCallback onSpin;

  @override
  State<_SpinButton> createState() => _SpinButtonState();
}

class _SpinButtonState extends State<_SpinButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didUpdateWidget(covariant _SpinButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinning && !_spinCtrl.isAnimating) {
      _spinCtrl.repeat();
    } else if (!widget.spinning && _spinCtrl.isAnimating) {
      _spinCtrl
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.spinning ? null : widget.onSpin,
      child: AnimatedScale(
        scale: widget.spinning ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.spinning
                  ? const [Color(0xFF78909C), Color(0xFF546E7A)]
                  : const [Color(0xFF69F0AE), Color(0xFF00C853)],
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.spinning ? Colors.blueGrey : AppTheme.accentGreen)
                    .withValues(alpha: 0.45),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: RotationTransition(
            turns: _spinCtrl,
            child: const Icon(Icons.refresh, size: 34, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
