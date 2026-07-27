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
import { slotsStatements } from './slots-statements.js';

function getConfig(): EconomyConfig {
  return slotsStatements().getConfig.get() as EconomyConfig;
}

function getEconomy(userId: string): UserEconomy {
  const row = slotsStatements().getEconomy.get(userId) as UserEconomy | undefined;
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
