import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../providers/auth_provider.dart';

class CoinProduct {
  CoinProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.coins,
  });
  final String id;
  final String title;
  final String description;
  final String price;
  final int coins;
}

class PurchasesService {
  static bool _mockMode = true;

  static final coinProducts = [
    CoinProduct(
      id: 'coins_50k',
      title: '50,000 monedas',
      description: 'Pack básico',
      price: '\$0.99',
      coins: 50000,
    ),
    CoinProduct(
      id: 'coins_200k',
      title: '200,000 monedas',
      description: 'Pack popular',
      price: '\$2.99',
      coins: 200000,
    ),
    CoinProduct(
      id: 'coins_1m',
      title: '1,000,000 monedas',
      description: 'Pack mega',
      price: '\$9.99',
      coins: 1000000,
    ),
  ];

  static Future<void> initialize() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(
        PurchasesConfiguration('appl_mock_key_for_dev'),
      );
      _mockMode = false;
    } catch (_) {
      _mockMode = true;
    }
  }

  static Future<void> purchaseProduct(String productId, WidgetRef ref) async {
    final context = ref.context;
    if (_mockMode) {
      if (context.mounted) _showMockPurchase(context, 'Compra simulada: $productId');
      await ref.read(authProvider.notifier).refreshProfile();
      return;
    }
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.availablePackages
          .where((p) => p.storeProduct.identifier == productId)
          .firstOrNull;
      if (package != null) {
        await Purchases.purchasePackage(package);
        await ref.read(authProvider.notifier).refreshProfile();
      }
    } catch (e) {
      if (context.mounted) _showMockPurchase(context, 'Error: $e');
    }
  }

  static Future<void> purchaseVip(WidgetRef ref) async {
    final context = ref.context;
    if (_mockMode) {
      if (context.mounted) _showMockPurchase(context, 'VIP activado (modo demo)');
      return;
    }
    try {
      final offerings = await Purchases.getOfferings();
      final vip = offerings.current?.availablePackages
          .where((p) => p.storeProduct.identifier == 'happygamba_vip')
          .firstOrNull;
      if (vip != null) await Purchases.purchasePackage(vip);
      await ref.read(authProvider.notifier).refreshProfile();
    } catch (e) {
      if (context.mounted) _showMockPurchase(context, 'VIP: $e');
    }
  }

  static Future<void> purchaseAdFree(WidgetRef ref) async {
    final context = ref.context;
    if (_mockMode) {
      if (context.mounted) _showMockPurchase(context, 'Sin ads activado (modo demo)');
      return;
    }
    try {
      final offerings = await Purchases.getOfferings();
      final adFree = offerings.current?.availablePackages
          .where((p) => p.storeProduct.identifier == 'happygamba_ad_free')
          .firstOrNull;
      if (adFree != null) await Purchases.purchasePackage(adFree);
      await ref.read(authProvider.notifier).refreshProfile();
    } catch (e) {
      if (context.mounted) _showMockPurchase(context, 'Ad-free: $e');
    }
  }

  static Future<void> restorePurchases(WidgetRef ref) async {
    final context = ref.context;
    if (_mockMode) {
      if (context.mounted) _showMockPurchase(context, 'Restauración simulada');
      return;
    }
    await Purchases.restorePurchases();
    await ref.read(authProvider.notifier).refreshProfile();
  }

  static void _showMockPurchase(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
