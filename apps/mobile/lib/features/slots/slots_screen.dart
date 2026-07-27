import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/ads_service.dart';
import '../../services/api_client.dart';

class SlotsScreen extends ConsumerStatefulWidget {
  const SlotsScreen({super.key});

  @override
  ConsumerState<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends ConsumerState<SlotsScreen> {
  static const _betSteps = [500, 1000, 2000, 5000];
  int _betIndex = 1;
  bool _spinning = false;
  List<List<String>> _grid = List.generate(5, (_) => List.filled(5, '?'));
  String? _lastWin;
  int _spinCount = 0;

  int get _bet => _betSteps[_betIndex];

  Future<void> _spin() async {
    if (_spinning) return;
    setState(() => _spinning = true);
    try {
      final result = await ref.read(apiClientProvider).spinSlots(_bet);
      for (final cascade in result.cascades) {
        setState(() => _grid = cascade.grid);
        await Future.delayed(const Duration(milliseconds: 600));
        if (cascade.wins.isNotEmpty) {
          setState(() {
            _lastWin = '+${NumberFormat('#,###').format(cascade.wins.first.payout)}';
          });
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }
      ref.read(authProvider.notifier).updateBalance(result.balance);
      _spinCount++;
      if (_spinCount % 10 == 0) {
        await AdsService.showInterstitial();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _spinning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(authProvider).valueOrNull?.balance ?? 0;
    final formatter = NumberFormat('#,###', 'es');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2E1A), Color(0xFF0D1117), Color(0xFF1A0A2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Lucky Forest Slots',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              _multiplierLegend(),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _slotGrid(),
                    ),
                    if (_lastWin != null)
                      Text(
                        _lastWin!,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                        ),
                      ).animate().scale().fadeIn().then().fadeOut(delay: 600.ms),
                  ],
                ),
              ),
              _controlBar(balance, formatter),
            ],
          ),
        ),
      ),
    );
  }

  Widget _multiplierLegend() {
    const tiers = [
      ('🥉', '0.2-4x'),
      ('🥈', '5-10x'),
      ('🥇', '20-50x'),
      ('💎', '100-500x'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tiers
            .map((t) => Column(
                  children: [
                    Text(t.$1, style: const TextStyle(fontSize: 20)),
                    Text(t.$2, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _slotGrid() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5D4037), width: 3),
      ),
      child: Column(
        children: List.generate(5, (r) {
          return Expanded(
            child: Row(
              children: List.generate(5, (c) {
                final sym = _grid[r][c];
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2838),
                      borderRadius: BorderRadius.circular(6),
                      border: sym == 'W'
                          ? Border.all(color: AppTheme.accentGold, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        _symbolLabel(sym),
                        style: TextStyle(
                          fontSize: sym.length > 2 ? 10 : 16,
                          fontWeight: FontWeight.bold,
                          color: _symbolColor(sym),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  String _symbolLabel(String sym) {
    const map = {
      'HAT': '🎩',
      'BOOT': '👢',
      'MUG': '🍺',
      'DICE': '🎲',
      'W': 'W',
      'FS': 'FS',
    };
    return map[sym] ?? sym;
  }

  Color _symbolColor(String sym) {
    if (sym == 'W') return AppTheme.accentGold;
    if (sym == 'FS') return AppTheme.accentGreen;
    return Colors.white;
  }

  Widget _controlBar(int balance, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black.withValues(alpha: 0.7),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('SALDO', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              Text(formatter.format(balance), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _betIndex > 0 ? () => setState(() => _betIndex--) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Column(
            children: [
              const Text('APUESTA', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              Text(formatter.format(_bet)),
            ],
          ),
          IconButton(
            onPressed: _betIndex < _betSteps.length - 1 ? () => setState(() => _betIndex++) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _spinning ? null : _spin,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _spinning ? Colors.grey : AppTheme.accentGreen,
                boxShadow: [
                  BoxShadow(color: AppTheme.accentGreen.withValues(alpha: 0.4), blurRadius: 12),
                ],
              ),
              child: _spinning
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                    )
                  : const Icon(Icons.refresh, size: 32, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
