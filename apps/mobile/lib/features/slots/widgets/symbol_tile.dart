import 'package:flutter/material.dart';

import '../../../core/theme.dart';

const kSlotSymbols = [
  '10',
  'J',
  'Q',
  'K',
  'A',
  'HAT',
  'BOOT',
  'MUG',
  'DICE',
  'W',
  'FS',
];

class SymbolTile extends StatelessWidget {
  const SymbolTile({
    super.key,
    required this.symbol,
    this.highlighted = false,
    this.dimmed = false,
    this.margin = 2,
  });

  final String symbol;
  final bool highlighted;
  final bool dimmed;
  final double margin;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(symbol);
    return Opacity(
      opacity: dimmed ? 0.35 : 1,
      child: Container(
        margin: EdgeInsets.all(margin),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: style.gradient,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: highlighted ? AppTheme.accentGold : style.border,
            width: highlighted ? 2.5 : 1.2,
          ),
          boxShadow: [
            if (highlighted)
              BoxShadow(
                color: AppTheme.accentGold.withValues(alpha: 0.65),
                blurRadius: 12,
                spreadRadius: 1,
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 6,
              right: 6,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: style.isIcon
                  ? Text(style.label, style: TextStyle(fontSize: style.fontSize))
                  : Text(
                      style.label,
                      style: TextStyle(
                        fontSize: style.fontSize,
                        fontWeight: FontWeight.w900,
                        color: style.foreground,
                        letterSpacing: style.label.length > 1 ? -1 : 0,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SymbolStyle {
  const _SymbolStyle({
    required this.label,
    required this.gradient,
    required this.border,
    required this.foreground,
    required this.fontSize,
    this.isIcon = false,
  });

  final String label;
  final List<Color> gradient;
  final Color border;
  final Color foreground;
  final double fontSize;
  final bool isIcon;
}

_SymbolStyle _styleFor(String symbol) {
  switch (symbol) {
    case 'W':
      return const _SymbolStyle(
        label: 'W',
        gradient: [Color(0xFFFFE082), Color(0xFFFF8F00)],
        border: Color(0xFFFFD54F),
        foreground: Color(0xFF3E2723),
        fontSize: 28,
      );
    case 'FS':
      return const _SymbolStyle(
        label: 'FS',
        gradient: [Color(0xFF69F0AE), Color(0xFF00C853)],
        border: Color(0xFFB9F6CA),
        foreground: Color(0xFF00330F),
        fontSize: 20,
      );
    case 'HAT':
      return const _SymbolStyle(
        label: '🎩',
        gradient: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        border: Color(0xFF81C784),
        foreground: Colors.white,
        fontSize: 26,
        isIcon: true,
      );
    case 'BOOT':
      return const _SymbolStyle(
        label: '👢',
        gradient: [Color(0xFF6D4C41), Color(0xFF3E2723)],
        border: Color(0xFFA1887F),
        foreground: Colors.white,
        fontSize: 26,
        isIcon: true,
      );
    case 'MUG':
      return const _SymbolStyle(
        label: '🍺',
        gradient: [Color(0xFFFFB300), Color(0xFFF57C00)],
        border: Color(0xFFFFE082),
        foreground: Colors.white,
        fontSize: 26,
        isIcon: true,
      );
    case 'DICE':
      return const _SymbolStyle(
        label: '🎲',
        gradient: [Color(0xFF5C6BC0), Color(0xFF283593)],
        border: Color(0xFF9FA8DA),
        foreground: Colors.white,
        fontSize: 26,
        isIcon: true,
      );
    case 'A':
      return const _SymbolStyle(
        label: 'A',
        gradient: [Color(0xFF37474F), Color(0xFF263238)],
        border: Color(0xFFFF8A65),
        foreground: Color(0xFFFF8A65),
        fontSize: 26,
      );
    case 'K':
      return const _SymbolStyle(
        label: 'K',
        gradient: [Color(0xFF37474F), Color(0xFF263238)],
        border: Color(0xFFFFD54F),
        foreground: Color(0xFFFFD54F),
        fontSize: 26,
      );
    case 'Q':
      return const _SymbolStyle(
        label: 'Q',
        gradient: [Color(0xFF37474F), Color(0xFF263238)],
        border: Color(0xFFCE93D8),
        foreground: Color(0xFFCE93D8),
        fontSize: 26,
      );
    case 'J':
      return const _SymbolStyle(
        label: 'J',
        gradient: [Color(0xFF37474F), Color(0xFF263238)],
        border: Color(0xFF80CBC4),
        foreground: Color(0xFF80CBC4),
        fontSize: 26,
      );
    case '10':
      return const _SymbolStyle(
        label: '10',
        gradient: [Color(0xFF37474F), Color(0xFF263238)],
        border: Color(0xFF90CAF9),
        foreground: Color(0xFF90CAF9),
        fontSize: 22,
      );
    default:
      return _SymbolStyle(
        label: symbol == '?' ? '•' : symbol,
        gradient: const [Color(0xFF1B2838), Color(0xFF0D1520)],
        border: const Color(0xFF455A64),
        foreground: Colors.white70,
        fontSize: 22,
      );
  }
}
