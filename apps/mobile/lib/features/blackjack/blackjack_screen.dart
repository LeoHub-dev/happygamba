import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';

class BlackjackScreen extends ConsumerStatefulWidget {
  const BlackjackScreen({super.key});

  @override
  ConsumerState<BlackjackScreen> createState() => _BlackjackScreenState();
}

class _BlackjackScreenState extends ConsumerState<BlackjackScreen> {
  static const _bets = [500, 1000, 2000, 5000];
  int _betIndex = 1;
  String? _sessionId;
  List<Map<String, String>> _playerCards = [];
  List<Map<String, String>> _dealerCards = [];
  int _playerTotal = 0;
  int? _dealerTotal;
  bool _canHit = false;
  bool _dealerHidden = true;
  String? _outcome;
  bool _loading = false;

  int get _bet => _bets[_betIndex];

  Future<void> _start() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(apiClientProvider).startBlackjack(_bet);
      setState(() {
        _sessionId = result.sessionId;
        _playerCards = result.playerCards;
        _dealerCards = result.dealerCards;
        _playerTotal = result.playerTotal;
        _canHit = result.canHit;
        _dealerHidden = true;
        _outcome = null;
        _dealerTotal = null;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _action(String action) async {
    if (_sessionId == null) return;
    setState(() => _loading = true);
    try {
      final result = await ref.read(apiClientProvider).blackjackAction(_sessionId!, action);
      setState(() {
        _playerCards = result.playerCards;
        _dealerCards = result.dealerCards;
        _playerTotal = result.playerTotal;
        _dealerTotal = result.dealerTotal;
        _canHit = result.canHit;
        _dealerHidden = result.dealerHidden;
        _outcome = result.outcome;
      });
      if (result.balance != null) {
        ref.read(authProvider.notifier).updateBalance(result.balance!);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'es');
    final inGame = _sessionId != null && _outcome == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Blackjack 21')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!inGame && _outcome == null) ...[
              const Text('Selecciona tu apuesta', style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _betIndex > 0 ? () => setState(() => _betIndex--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(formatter.format(_bet), style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(
                    onPressed: _betIndex < _bets.length - 1 ? () => setState(() => _betIndex++) : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _loading ? null : _start,
                child: const Text('Repartir'),
              ),
            ] else ...[
              _handSection('Dealer', _dealerCards, _dealerHidden ? null : _dealerTotal),
              const SizedBox(height: 32),
              _handSection('Tú', _playerCards, _playerTotal),
              const Spacer(),
              if (_outcome != null) ...[
                Text(
                  _outcomeLabel(_outcome!),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _outcome == 'win' ? AppTheme.accentGreen : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => setState(() {
                  _sessionId = null;
                  _outcome = null;
                }), child: const Text('Nueva mano')),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _loading || !_canHit ? null : () => _action('hit'),
                      child: const Text('Pedir'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _loading ? null : () => _action('stand'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold),
                      child: const Text('Plantarse'),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _outcomeLabel(String o) {
    switch (o) {
      case 'win':
        return '¡Ganaste!';
      case 'lose':
        return 'Perdiste';
      default:
        return 'Empate';
    }
  }

  Widget _handSection(String label, List<Map<String, String>> cards, int? total) {
    return Column(
      children: [
        Text('$label${total != null ? ' ($total)' : ''}'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: cards.map((c) => _cardWidget(c)).toList(),
        ),
      ],
    );
  }

  Widget _cardWidget(Map<String, String> card) {
    final isHidden = card['rank'] == '?' || card.isEmpty;
    return Container(
      width: 56,
      height: 80,
      decoration: BoxDecoration(
        color: isHidden ? AppTheme.accentPurple : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: isHidden
          ? const Center(child: Icon(Icons.question_mark, color: Colors.white))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(card['rank'] ?? '', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                Text(card['suit'] ?? '', style: TextStyle(color: _suitColor(card['suit'] ?? ''))),
              ],
            ),
    );
  }

  Color _suitColor(String suit) {
    if (suit.contains('♥') || suit.contains('♦')) return Colors.red;
    return Colors.black;
  }
}
