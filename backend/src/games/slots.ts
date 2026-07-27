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
import { buildCascades } from './slots-clusters.js';

function getConfig(): EconomyConfig {
  return getDb().prepare('SELECT * FROM economy_config WHERE id = 1').get() as EconomyConfig;
}

function getEconomy(userId: string): UserEconomy {
  const row = getDb()
    .prepare('SELECT * FROM user_economy WHERE user_id = ?')
    .get(userId) as UserEconomy | undefined;
  if (!row) throw new Error('Economy not found');
  return row;
}

export function spinSlots(userId: string, bet: number) {
  if (bet < 100 || bet > 100000) throw new Error('Bet must be between 100 and 100000');

  const economy = getEconomy(userId);
  if (economy.balance < bet) throw new Error('Insufficient balance');

  const config = getConfig();
  const rng = createRng();
  const decision = decideOutcome(economy, bet, config, rng);

  const rawPayout = calculatePayout(bet, decision, rng);
  const targetPayout = decision.shouldWin
    ? Math.max(rawPayout, Math.floor(bet * decision.multiplierMin))
    : 0;

  const { cascades, totalPayout } = buildCascades({
    shouldWin: decision.shouldWin && targetPayout > 0,
    targetPayout,
    bet,
    rng,
  });

  const updated = applyBetResult(economy, bet, totalPayout, config);
  const db = getDb();

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
      JSON.stringify({
        tier: decision.tier,
        cascades: cascades.length,
        payStyle: 'cluster',
      })
    );
  })();

  return {
    bet,
    cascades,
    totalPayout,
    balance: updated.balance,
    tier: decision.tier,
    phase: decision.phase,
    payStyle: 'cluster' as const,
  };
}
