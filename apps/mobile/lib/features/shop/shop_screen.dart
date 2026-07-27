import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../services/purchases_service.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = PurchasesService.coinProducts;

    return Scaffold(
      appBar: AppBar(title: const Text('Tienda de monedas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Moneda ficticia para entretenimiento. Sin valor real.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          ...products.map((p) => Card(
                child: ListTile(
                  leading: const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 32),
                  title: Text(p.title),
                  subtitle: Text(p.description),
                  trailing: ElevatedButton(
                    onPressed: () => PurchasesService.purchaseProduct(p.id, ref),
                    child: Text(p.price),
                  ),
                ),
              )),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => PurchasesService.restorePurchases(ref),
            child: const Text('Restaurar compras'),
          ),
        ],
      ),
    );
  }
}
