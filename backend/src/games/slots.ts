import { v4 as uuid } from 'uuid';
import { getDb } from '../db.js';
import {
  applyBetResult,
  calculatePayout,
  decideOutcome,
  type EconomyConfig,
  type UserEconomy,
} from '../economy/engine.js';
import { createRng } from '../util/rng.js';
import { slotsStatements } from './slots-statements.js';

const SYMBOLS = ['10', 'J', 'Q', 'K', 'A', 'HAT', 'BOOT', 'MUG', 'DICE', 'W', 'FS'];

function getConfig(): EconomyConfig {
  return slotsStatements().getConfig.get() as EconomyConfig;
}

function getEconomy(userId: string): UserEconomy {
  const row = slotsStatements().getEconomy.get(userId) as UserEconomy | undefined;
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

function generateWinningGrid(
  symbol: string,
  rng: () => number
): { grid: string[][]; winRow: number } {
  const grid = randomGrid(rng);
  const winRow = Math.floor(rng() * 5);
  for (let c = 0; c < 3; c++) {
    grid[winRow][c] = symbol;
  }
  return { grid, winRow };
}

export interface CascadeStep {
  grid: string[][];
  wins: { cells: [number, number][]; payout: number; mult: number }[];
  removed: [number, number][];
}

export function spinSlots(userId: string, bet: number) {
  if (bet < 100 || bet > 100000) throw new Error('Bet must be between 100 and 100000');

  const economy = getEconomy(userId);
  if (economy.balance < bet) throw new Error('Insufficient balance');

  const config = getConfig();
  const rng = createRng();

  const decision = decideOutcome(economy, bet, config, rng);
  const cascades: CascadeStep[] = [];
  let totalPayout = 0;

  // Always at least one cascade so the client always has a reel result to show.
  const steps = Math.max(1, decision.shouldWin ? 1 + Math.floor(rng() * 2) : 1);
  for (let s = 0; s < steps; s++) {
    const stepDecision =
      s === 0 ? decision : { ...decision, shouldWin: rng() < 0.4, multiplierMin: 1, multiplierMax: 2 };
    const payout = s === 0 ? calculatePayout(bet, stepDecision, rng) : Math.floor(bet * (1 + rng()));
    totalPayout += payout;

    const symbol = SYMBOLS[Math.floor(rng() * 6)];
    let grid: string[][];
    let winCells: [number, number][] = [];
    if (stepDecision.shouldWin) {
      const generated = generateWinningGrid(symbol, rng);
      grid = generated.grid;
      winCells = [
        [generated.winRow, 0],
        [generated.winRow, 1],
        [generated.winRow, 2],
      ];
    } else {
      grid = randomGrid(rng);
    }

    cascades.push({
      grid,
      wins: winCells.length
        ? [{ cells: winCells, payout, mult: payout / Math.max(bet, 1) }]
        : [],
      removed: winCells,
    });
  }

  const updated = applyBetResult(economy, bet, totalPayout, config);
  const s = slotsStatements();

  getDb().transaction(() => {
    s.updateEconomy.run(
      updated.balance,
      updated.peak_balance,
      updated.phase,
      updated.session_wins,
      updated.session_losses,
      updated.total_bets,
      updated.last_bet_at,
      userId
    );
    s.insertBet.run(
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
