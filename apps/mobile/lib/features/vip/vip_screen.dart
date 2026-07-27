import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/purchases_service.dart';

class VipScreen extends ConsumerWidget {
  const VipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).valueOrNull;
    final isVip = profile?.isVip ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('VIP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.diamond, size: 80, color: AppTheme.accentGold),
            const SizedBox(height: 16),
            Text(
              isVip ? 'Miembro VIP activo' : 'Hazte VIP',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            const _BenefitRow(icon: Icons.block, text: 'Sin publicidad'),
            const _BenefitRow(icon: Icons.card_giftcard, text: 'Bonus diario x2'),
            const _BenefitRow(icon: Icons.star, text: 'Badge VIP en lobby'),
            const _BenefitRow(icon: Icons.casino, text: 'Acceso sala premium'),
            const Spacer(),
            if (!isVip) ...[
              ElevatedButton(
                onPressed: () => PurchasesService.purchaseVip(ref),
                child: const Text('VIP mensual — \$4.99/mes'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => PurchasesService.purchaseAdFree(ref),
                child: const Text('Solo sin ads — \$2.99/mes'),
              ),
            ] else
              const Text('¡Gracias por ser VIP!', style: TextStyle(color: AppTheme.accentGreen)),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentGreen),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
