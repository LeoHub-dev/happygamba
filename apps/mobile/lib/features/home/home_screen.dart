import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/ads_service.dart';
import '../../services/api_client.dart';
import '../../widgets/balance_chip.dart';
import '../../widgets/game_card.dart';
import '../../widgets/live_bets_feed.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('HappyGamba', style: TextStyle(color: AppTheme.accentGreen)),
        actions: [
          BalanceChip(balance: profile.balance),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!profile.isAdFree)
            SizedBox(
              height: 50,
              child: AdsService.bannerWidget(),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _tabButton('Casino', 0),
                _tabButton('VIP', 1, vip: profile.isVip),
                _tabButton('Promos', 2),
              ],
            ),
          ),
          Expanded(child: _buildTab(profile)),
        ],
      ),
      bottomNavigationBar: profile.isAdFree
          ? null
          : null,
    );
  }

  Widget _tabButton(String label, int index, {bool vip = false}) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppTheme.accentGreen : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textMuted,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (vip) ...[
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 14, color: AppTheme.accentGold),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(profile) {
    switch (_tabIndex) {
      case 1:
        return _vipTab(profile);
      case 2:
        return _promosTab(profile);
      default:
        return _casinoTab(profile);
    }
  }

  Widget _casinoTab(profile) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: GameCard(
                title: 'Lucky Forest Slots',
                subtitle: '5x5 cascades',
                icon: Icons.casino,
                color: AppTheme.accentGreen,
                onTap: () => context.push('/slots'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GameCard(
                title: 'Blackjack 21',
                subtitle: 'vs Dealer',
                icon: Icons.style,
                color: AppTheme.accentPurple,
                onTap: () => context.push('/blackjack'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Apuestas en vivo', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const LiveBetsFeed(),
      ],
    );
  }

  Widget _vipTab(profile) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.diamond, size: 64, color: profile.isVip ? AppTheme.accentGold : AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            profile.isVip ? 'Eres VIP' : 'Sala VIP',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Sin publicidad, bonus diario mayor, badge exclusivo y acceso a juegos premium.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => context.push('/vip'),
            child: Text(profile.isVip ? 'Gestionar VIP' : 'Hazte VIP'),
          ),
        ],
      ),
    );
  }

  Widget _promosTab(profile) {
    final formatter = NumberFormat('#,###', 'es');
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _promoCard(
            'Bonus diario',
            '+${formatter.format(profile.isVip ? 10000 : 5000)} monedas',
            Icons.card_giftcard,
            () async {
              try {
                final result = await ref.read(apiClientProvider).claimDailyBonus();
                ref.read(authProvider.notifier).updateBalance(result.balance);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('¡+${formatter.format(result.bonus)} monedas!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
          ),
          const SizedBox(height: 12),
          _promoCard(
            'Ver anuncio',
            '+5,000 monedas (rewarded)',
            Icons.play_circle,
            () async {
              await AdsService.showRewardedAd(onReward: () async {
                final result = await ref.read(apiClientProvider).claimDailyBonus(rewarded: true);
                ref.read(authProvider.notifier).updateBalance(result.balance);
              });
            },
          ),
          const SizedBox(height: 12),
          _promoCard('Tienda de monedas', 'Compra packs', Icons.shopping_cart, () {
            context.push('/shop');
          }),
        ],
      ),
    );
  }

  Widget _promoCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.accentGreen),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
