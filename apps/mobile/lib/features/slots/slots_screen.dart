import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/ads_service.dart';
import '../../services/api_client.dart';
import 'widgets/forest_backdrop.dart';
import 'widgets/reel_column.dart';
import 'widgets/slot_machine_frame.dart';
import 'widgets/spin_controls.dart';
import 'widgets/symbol_tile.dart';
import 'widgets/win_overlay.dart';

class SlotsScreen extends ConsumerStatefulWidget {
  const SlotsScreen({super.key});

  @override
  ConsumerState<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends ConsumerState<SlotsScreen> {
  static const _rows = 5;
  static const _cols = 5;
  static const _betSteps = [500, 1000, 2000, 5000];

  final List<GlobalKey<ReelColumnState>> _reelKeys =
      List.generate(5, (_) => GlobalKey<ReelColumnState>());

  int _betIndex = 1;
  bool _spinning = false;
  late List<List<String>> _grid;
  Set<(int, int)> _highlighted = {};
  bool _dimNonWins = false;
  String? _lastWin;
  int _spinCount = 0;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _grid = List.generate(
      _rows,
      (_) => List.generate(
        _cols,
        (_) => kSlotSymbols[rng.nextInt(kSlotSymbols.length)],
      ),
    );
  }

  int get _bet => _betSteps[_betIndex];

  List<String> _columnSymbols(List<List<String>> grid, int col) {
    return [for (var r = 0; r < _rows; r++) grid[r][col]];
  }

  Future<ReelColumnState> _reelState(int col) async {
    for (var i = 0; i < 10; i++) {
      final state = _reelKeys[col].currentState;
      if (state != null) return state;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    throw StateError('Reel $col not ready');
  }

  Future<void> _spinReelsTo(List<List<String>> target) async {
    final futures = <Future<void>>[];
    for (var c = 0; c < _cols; c++) {
      final col = c;
      futures.add(() async {
        await Future<void>.delayed(Duration(milliseconds: 80 * col));
        final reel = await _reelState(col);
        // Always enough fillers so win AND loss spins are visibly rolling.
        await reel.spinTo(
          _columnSymbols(target, col),
          fillerCount: 16 + col * 2,
          duration: Duration(milliseconds: 1000 + col * 100),
        );
      }());
    }
    await Future.wait(futures);
  }

  Future<void> _dropReelsTo(List<List<String>> target) async {
    final futures = <Future<void>>[];
    for (var c = 0; c < _cols; c++) {
      final col = c;
      futures.add(() async {
        await Future<void>.delayed(Duration(milliseconds: 40 * col));
        final reel = await _reelState(col);
        await reel.dropIn(
          _columnSymbols(target, col),
          duration: Duration(milliseconds: 420 + col * 40),
        );
      }());
    }
    await Future.wait(futures);
  }

  Future<void> _playCascade(CascadeStep cascade, {required bool isFirst}) async {
    if (isFirst) {
      await _spinReelsTo(cascade.grid);
    } else {
      await _dropReelsTo(cascade.grid);
    }
    if (!mounted) return;

    final hasWin = cascade.wins.isNotEmpty;
    setState(() {
      _grid = cascade.grid.map((row) => List<String>.from(row)).toList();
      _highlighted = cascade.winningCells;
      _dimNonWins = hasWin;
      if (hasWin) {
        final payout = cascade.wins.fold<int>(0, (sum, w) => sum + w.payout);
        _lastWin = '+${NumberFormat('#,###').format(payout)}';
      }
    });

    // Hold landed result so the new grid is readable (especially losses).
    await Future<void>.delayed(
      Duration(milliseconds: hasWin ? 900 : 500),
    );

    if (!mounted) return;
    setState(() {
      _highlighted = {};
      _dimNonWins = false;
    });
  }

  Future<void> _spin() async {
    if (_spinning) return;
    setState(() {
      _spinning = true;
      _lastWin = null;
      _highlighted = {};
      _dimNonWins = false;
    });

    try {
      final result = await ref.read(apiClientProvider).spinSlots(_bet);
      if (!mounted) return;

      if (result.cascades.isEmpty) {
        // Backend should always return >=1 cascade; never surface Bad state to UI.
        ref.read(authProvider.notifier).updateBalance(result.balance);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo animar el spin. Intenta de nuevo.')),
          );
        }
        return;
      }

      for (var i = 0; i < result.cascades.length; i++) {
        if (!mounted) return;
        await _playCascade(result.cascades[i], isFirst: i == 0);
      }

      if (!mounted) return;
      // Sync grid to final cascade in case a reel finished early.
      setState(() {
        _grid = result.cascades.last.grid
            .map((row) => List<String>.from(row))
            .toList();
      });
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

    return Scaffold(
      body: ForestBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _spinning ? null : () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Lucky Forest',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentGreen,
                          letterSpacing: 0.5,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const MultiplierLegend(),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SlotMachineFrame(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            for (var c = 0; c < _cols; c++) ...[
                              if (c > 0)
                                Container(
                                  width: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        AppTheme.accentGold.withValues(alpha: 0.35),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: ReelColumn(
                                  key: _reelKeys[c],
                                  rows: _rows,
                                  symbols: _columnSymbols(_grid, c),
                                  highlightedRows: {
                                    for (final cell in _highlighted)
                                      if (cell.$2 == c) cell.$1,
                                  },
                                  dimmed: _dimNonWins,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_lastWin != null) WinOverlay(text: _lastWin!),
                  ],
                ),
              ),
              SpinControls(
                balance: balance,
                bet: _bet,
                spinning: _spinning,
                canDecreaseBet: _betIndex > 0,
                canIncreaseBet: _betIndex < _betSteps.length - 1,
                onDecreaseBet: () => setState(() => _betIndex--),
                onIncreaseBet: () => setState(() => _betIndex++),
                onSpin: _spin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
