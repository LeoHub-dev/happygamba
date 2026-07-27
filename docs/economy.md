# HappyGamba Economy Engine

## Phases

- **rising**: balance < 85% of ceiling — ~80% win rate, multipliers 1.2x–2.5x
- **falling**: balance >= 90% of ceiling — ~25% win rate
- **recovery**: balance <= floor — returns to rising with boosted wins

## Post-peak behavior

When `peak_balance >= 70% of ceiling`:
- Big bets (>10% of balance): ~92% loss rate
- Small bets (<=5%): ~65% win rate

## Config

All parameters live in `economy_config` table and can be tuned without code changes.
