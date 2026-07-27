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

  Future<void> _startAllRolling() async {
    final futures = <Future<void>>[];
    for (var c = 0; c < _cols; c++) {
      final col = c;
      futures.add(() async {
        await Future<void>.delayed(Duration(milliseconds: 40 * col));
        final reel = await _reelState(col);
        await reel.startRolling(fillerCount: 56 + col * 4);
      }());
    }
    await Future.wait(futures);
  }

  Future<void> _landAllOn(List<List<String>> target) async {
    final futures = <Future<void>>[];
    for (var c = 0; c < _cols; c++) {
      final col = c;
      futures.add(() async {
        await Future<void>.delayed(Duration(milliseconds: 70 * col));
        final reel = await _reelState(col);
        await reel.landOn(
          _columnSymbols(target, col),
          extraFillers: 8 + col,
          duration: Duration(milliseconds: 550 + col * 80),
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

  Future<void> _showCascadeResult(CascadeStep cascade) async {
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

    await Future<void>.delayed(
      Duration(milliseconds: hasWin ? 700 : 350),
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
      // 1) Reels start moving immediately — don't wait on the network.
      final rollStarted = DateTime.now();
      final rolling = _startAllRolling();
      // 2) Fetch result in parallel.
      final apiFuture = ref.read(apiClientProvider).spinSlots(_bet);

      await rolling;
      final result = await apiFuture;
      if (!mounted) return;

      // Keep a brief minimum roll so instant API responses still feel snappy, not abrupt.
      const minRoll = Duration(milliseconds: 280);
      final elapsed = DateTime.now().difference(rollStarted);
      if (elapsed < minRoll) {
        await Future<void>.delayed(minRoll - elapsed);
      }
      if (!mounted) return;

      if (result.cascades.isEmpty) {
        for (var c = 0; c < _cols; c++) {
          await _reelKeys[c].currentState?.abortToIdle();
        }
        ref.read(authProvider.notifier).updateBalance(result.balance);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo animar el spin. Intenta de nuevo.')),
          );
        }
        return;
      }

      // 3) Land first cascade (API already back; reels have been rolling).
      final first = result.cascades.first;
      await _landAllOn(first.grid);
      await _showCascadeResult(first);

      // 4) Extra cascades tumble in.
      for (var i = 1; i < result.cascades.length; i++) {
        if (!mounted) return;
        final cascade = result.cascades[i];
        await _dropReelsTo(cascade.grid);
        await _showCascadeResult(cascade);
      }

      if (!mounted) return;
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
      for (var c = 0; c < _cols; c++) {
        await _reelKeys[c].currentState?.abortToIdle();
      }
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
