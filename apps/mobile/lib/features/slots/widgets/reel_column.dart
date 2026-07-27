import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'symbol_tile.dart';

/// A single vertical slot reel: visible window of [rows] symbols that scrolls
/// a strip so the previous result rolls out and new symbols roll in.
class ReelColumn extends StatefulWidget {
  const ReelColumn({
    super.key,
    required this.symbols,
    required this.rows,
    this.highlightedRows = const {},
    this.dimmed = false,
  });

  final List<String> symbols;
  final int rows;
  final Set<int> highlightedRows;
  final bool dimmed;

  @override
  State<ReelColumn> createState() => ReelColumnState();
}

class ReelColumnState extends State<ReelColumn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<String> _strip = [];
  double _cellHeight = 0;
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _strip = List<String>.from(widget.symbols);
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void didUpdateWidget(covariant ReelColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_spinning &&
        !_controller.isAnimating &&
        oldWidget.symbols.join() != widget.symbols.join()) {
      _strip = List<String>.from(widget.symbols);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ensureLaidOut() async {
    if (_cellHeight > 0) return;
    // Wait until LayoutBuilder has measured the reel viewport.
    for (var i = 0; i < 8; i++) {
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) return;
      if (_cellHeight > 0) return;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  List<String> get _currentVisible {
    if (_strip.length >= widget.rows) {
      return _strip.sublist(0, widget.rows);
    }
    return List<String>.from(widget.symbols);
  }

  /// Spins the reel so [target] lands in the viewport.
  /// Always rolls fillers so losses still look like a real spin.
  Future<void> spinTo(
    List<String> target, {
    int fillerCount = 16,
    Duration duration = const Duration(milliseconds: 1150),
  }) async {
    assert(target.length == widget.rows);
    await _ensureLaidOut();
    if (!mounted || _cellHeight <= 0) return;

    final rng = Random();
    final start = _currentVisible;
    final fillers = List.generate(
      fillerCount,
      (_) => kSlotSymbols[rng.nextInt(kSlotSymbols.length)],
    );

    setState(() {
      _strip = [...start, ...fillers, ...target];
      _spinning = true;
      _controller.value = 0;
    });

    // One frame so the new strip is built before animating.
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;

    final endOffset = (start.length + fillers.length) * _cellHeight;
    await _controller.animateTo(
      endOffset,
      duration: duration,
      curve: const Cubic(0.12, 0.7, 0.2, 1.0),
    );

    if (!mounted) return;
    setState(() {
      _strip = List<String>.from(target);
      _controller.value = 0;
      _spinning = false;
    });
  }

  /// New symbols enter from above and fall into place (cascade refill).
  Future<void> dropIn(
    List<String> target, {
    Duration duration = const Duration(milliseconds: 480),
  }) async {
    assert(target.length == widget.rows);
    await _ensureLaidOut();
    if (!mounted || _cellHeight <= 0) return;

    final below = _currentVisible;
    setState(() {
      _strip = [...target, ...below];
      _spinning = true;
      _controller.value = 0;
    });

    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;

    await _controller.animateTo(
      target.length * _cellHeight,
      duration: duration,
      curve: Curves.easeOutCubic,
    );

    if (!mounted) return;
    setState(() {
      _strip = List<String>.from(target);
      _controller.value = 0;
      _spinning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _cellHeight = constraints.maxHeight / widget.rows;
        final width = constraints.maxWidth;
        final offset = _controller.value;
        final displayStrip =
            _strip.isEmpty ? List<String>.from(widget.symbols) : _strip;

        // Only build tiles near the viewport — avoids Column overflow on long strips.
        final first = (_cellHeight > 0)
            ? (offset / _cellHeight).floor().clamp(0, displayStrip.length - 1)
            : 0;
        final last = (_cellHeight > 0)
            ? ((offset + constraints.maxHeight) / _cellHeight)
                .ceil()
                .clamp(0, displayStrip.length - 1)
            : (widget.rows - 1);

        return ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      const Color(0xFF0B1620),
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
              for (var i = first; i <= last; i++)
                Positioned(
                  top: i * _cellHeight - offset,
                  left: 0,
                  width: width,
                  height: _cellHeight,
                  child: SymbolTile(
                    symbol: displayStrip[i],
                    highlighted: !_spinning &&
                        i < widget.rows &&
                        widget.highlightedRows.contains(i),
                    dimmed: widget.dimmed &&
                        !_spinning &&
                        !widget.highlightedRows.contains(i),
                  ),
                ),
              IgnorePointer(
                child: Column(
                  children: [
                    Container(
                      height: _cellHeight * 0.3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: _cellHeight * 0.3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_spinning)
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.04),
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
