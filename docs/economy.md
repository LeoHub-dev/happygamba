# HappyGamba Economy Engine

## Phases

- **rising**: balance < 85% of ceiling — ~80% win rate, multipliers 1.2x–2.5x
- **falling**: balance >= 90% of ceiling — ~25% win rate
- **recovery**: balance <= floor — returns to rising with boosted wins

## Post-peak behavior

When `peak_balance >= 70% of ceiling`:
- Big bets (>10% of balance): ~92% loss rate
- Small bets (<=5%): ~65% win rate

## Slots pay style (cluster / Hacksaw-like)

- Wins are **clusters**: 4+ same symbols connected up/down/left/right
- `W` is wild and joins adjacent clusters; `FS` does not pay in clusters
- After a win, symbols tumble down and new ones fill from above
- **Extra cascades only happen if the new grid still has clusters** (no random fake extra roll)

## Config

All economy parameters live in `economy_config` and can be tuned without code changes.
