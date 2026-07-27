import 'dart:math';

import 'package:flutter/material.dart';

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

  /// Spins the reel so [target] (length == rows) lands in the viewport.
  /// Current symbols roll out; fillers and target roll in visibly.
  Future<void> spinTo(
    List<String> target, {
    int fillerCount = 16,
    Duration duration = const Duration(milliseconds: 1150),
  }) async {
    assert(target.length == widget.rows);
    if (_cellHeight <= 0) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (!mounted || _cellHeight <= 0) return;
    }

    final rng = Random();
    final start = List<String>.from(
      _strip.length >= widget.rows ? _strip.sublist(0, widget.rows) : widget.symbols,
    );
    final fillers = List.generate(
      fillerCount,
      (_) => kSlotSymbols[rng.nextInt(kSlotSymbols.length)],
    );

    setState(() {
      _strip = [...start, ...fillers, ...target];
      _spinning = true;
      _controller.value = 0;
    });

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
    if (_cellHeight <= 0) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (!mounted || _cellHeight <= 0) return;
    }

    setState(() {
      // Target sits above the current visible strip, then we scroll it down.
      _strip = [...target, ...List<String>.from(widget.symbols)];
      _spinning = true;
      _controller.value = 0;
    });

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

        return ClipRect(
          child: Stack(
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
              Transform.translate(
                offset: Offset(0, -offset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < displayStrip.length; i++)
                      SizedBox(
                        height: _cellHeight,
                        width: width,
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
                  ],
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
