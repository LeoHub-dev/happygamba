import { v4 as uuid } from 'uuid';
import { getDb } from '../db.js';
import {
  applyBetResult,
  calculatePayout,
  decideOutcome,
  type EconomyConfig,
  type UserEconomy,
} from '../economy/engine.js';

const SYMBOLS = ['10', 'J', 'Q', 'K', 'A', 'HAT', 'BOOT', 'MUG', 'DICE', 'W', 'FS'];

function getConfig(): EconomyConfig {
  return getDb().prepare('SELECT * FROM economy_config WHERE id = 1').get() as EconomyConfig;
}

function getEconomy(userId: string): UserEconomy {
  const row = getDb()
    .prepare('SELECT * FROM user_economy WHERE user_id = ?')
    .get(userId) as UserEconomy;
  if (!row) throw new Error('Economy not found');
  return row;
}

function randomGrid(rng: () => number): string[][] {
  const grid: string[][] = [];
  for (let r = 0; r < 5; r++) {
    const row: string[] = [];
    for (let c = 0; c < 5; c++) {
      row.push(SYMBOLS[Math.floor(rng() * SYMBOLS.length)]);
    }
    grid.push(row);
  }
  return grid;
}

function generateWinningGrid(symbol: string, rng: () => number): string[][] {
  const grid = randomGrid(rng);
  const row = Math.floor(rng() * 5);
  for (let c = 0; c < 3; c++) {
    grid[row][c] = symbol;
  }
  return grid;
}

export interface CascadeStep {
  grid: string[][];
  wins: { cells: [number, number][]; payout: number; mult: number }[];
  removed: [number, number][];
}

export function spinSlots(userId: string, bet: number) {
  if (bet < 100 || bet > 100000) throw new Error('Bet must be between 100 and 100000');

  const db = getDb();
  const economy = getEconomy(userId);
  if (economy.balance < bet) throw new Error('Insufficient balance');

  const config = getConfig();
  let seed = Date.now() ^ (Math.random() * 0xffffffff);
  const rng = () => {
    seed = (seed * 16807 + 1) % 2147483647;
    return seed / 2147483647;
  };

  const decision = decideOutcome(economy, bet, config, rng);
  const cascades: CascadeStep[] = [];
  let totalPayout = 0;

  const steps = decision.shouldWin ? 1 + Math.floor(rng() * 2) : 1;
  for (let s = 0; s < steps; s++) {
    const stepBet = s === 0 ? bet : 0;
    const stepDecision =
      s === 0 ? decision : { ...decision, shouldWin: rng() < 0.4, multiplierMin: 1, multiplierMax: 2 };
    const payout = s === 0 ? calculatePayout(bet, stepDecision, rng) : Math.floor(bet * (1 + rng()));
    totalPayout += payout;

    const symbol = SYMBOLS[Math.floor(rng() * 6)];
    const grid = stepDecision.shouldWin ? generateWinningGrid(symbol, rng) : randomGrid(rng);
    const winCells: [number, number][] = stepDecision.shouldWin
      ? [
          [Math.floor(rng() * 5), 0],
          [Math.floor(rng() * 5), 1],
          [Math.floor(rng() * 5), 2],
        ]
      : [];

    cascades.push({
      grid,
      wins: winCells.length
        ? [{ cells: winCells, payout, mult: payout / Math.max(bet, 1) }]
        : [],
      removed: winCells,
    });
  }

  const updated = applyBetResult(economy, bet, totalPayout, config);

  db.transaction(() => {
    db.prepare(
      `UPDATE user_economy SET balance=?, peak_balance=?, phase=?, session_wins=?, session_losses=?,
       total_bets=?, last_bet_at=? WHERE user_id=?`
    ).run(
      updated.balance,
      updated.peak_balance,
      updated.phase,
      updated.session_wins,
      updated.session_losses,
      updated.total_bets,
      updated.last_bet_at,
      userId
    );
    db.prepare(
      `INSERT INTO bet_history (id, user_id, game_type, bet_amount, payout, balance_after, phase, metadata)
       VALUES (?, ?, 'slots', ?, ?, ?, ?, ?)`
    ).run(
      uuid(),
      userId,
      bet,
      totalPayout,
      updated.balance,
      decision.phase,
      JSON.stringify({ tier: decision.tier, cascades: cascades.length })
    );
  })();

  return {
    bet,
    cascades,
    totalPayout,
    balance: updated.balance,
    tier: decision.tier,
    phase: decision.phase,
  };
}
