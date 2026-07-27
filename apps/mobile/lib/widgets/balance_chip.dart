import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';

class BalanceChip extends StatelessWidget {
  const BalanceChip({super.key, required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat('#,###', 'es').format(balance);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 18),
          const SizedBox(width: 4),
          Text(formatted, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
