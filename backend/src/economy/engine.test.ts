import { describe, expect, it } from 'vitest';
import {
  applyBetResult,
  calculatePayout,
  decideOutcome,
  resolvePhase,
  type EconomyConfig,
  type UserEconomy,
} from './engine.js';

const defaultConfig: EconomyConfig = {
  initial_balance: 30000,
  ceiling_multiplier: 5.0,
  floor_multiplier: 1.0,
  win_rate_rising: 0.8,
  win_rate_falling: 0.25,
  win_rate_neutral: 0.55,
  big_bet_ratio: 0.1,
  small_bet_ratio: 0.05,
  post_peak_big_bet_loss_rate: 0.92,
};

function makeEconomy(overrides: Partial<UserEconomy> = {}): UserEconomy {
  return {
    user_id: 'test',
    balance: 30000,
    initial_balance: 30000,
    peak_balance: 30000,
    phase: 'rising',
    session_wins: 0,
    session_losses: 0,
    last_bet_at: null,
    total_bets: 0,
    last_daily_bonus_at: null,
    ...overrides,
  };
}

describe('resolvePhase', () => {
  it('transitions to falling near ceiling', () => {
    const economy = makeEconomy({ balance: 135000, phase: 'rising' });
    expect(resolvePhase(economy, defaultConfig)).toBe('falling');
  });

  it('transitions to recovery at floor', () => {
    const economy = makeEconomy({ balance: 30000, phase: 'falling' });
    expect(resolvePhase(economy, defaultConfig)).toBe('recovery');
  });
});

describe('decideOutcome', () => {
  it('forces loss on big bet after peak', () => {
    const economy = makeEconomy({
      balance: 100000,
      peak_balance: 140000,
      phase: 'falling',
    });
    let losses = 0;
    for (let i = 0; i < 100; i++) {
      const d = decideOutcome(economy, 15000, defaultConfig, () => 0.5);
      if (!d.shouldWin) losses++;
    }
    expect(losses).toBeGreaterThan(80);
  });

  it('allows wins on small bet after peak', () => {
    const economy = makeEconomy({
      balance: 100000,
      peak_balance: 140000,
      phase: 'falling',
    });
    let wins = 0;
    for (let i = 0; i < 100; i++) {
      const d = decideOutcome(economy, 2000, defaultConfig, () => 0.1);
      if (d.shouldWin) wins++;
    }
    expect(wins).toBeGreaterThan(50);
  });
});

describe('simulation', () => {
  it('does not exceed ceiling without purchases in rising phase simulation', () => {
    let economy = makeEconomy();
    const ceiling = defaultConfig.initial_balance * defaultConfig.ceiling_multiplier;
    let seed = 42;
    const rng = () => {
      seed = (seed * 16807) % 2147483647;
      return seed / 2147483647;
    };

    for (let i = 0; i < 500; i++) {
      const bet = 1000;
      const decision = decideOutcome(economy, bet, defaultConfig, rng);
      const payout = calculatePayout(bet, decision, rng);
      economy = applyBetResult(economy, bet, payout, defaultConfig);
    }

    expect(economy.peak_balance).toBeLessThanOrEqual(ceiling * 1.25);
  });

  it('activates recovery after falling to floor', () => {
    let economy = makeEconomy({ balance: 35000, phase: 'falling' });
    let seed = 99;
    const rng = () => {
      seed = (seed * 16807) % 2147483647;
      return seed / 2147483647;
    };

    for (let i = 0; i < 200; i++) {
      const bet = 2000;
      const decision = decideOutcome(economy, bet, defaultConfig, rng);
      const payout = calculatePayout(bet, decision, rng);
      economy = applyBetResult(economy, bet, payout, defaultConfig);
      if (economy.balance <= economy.initial_balance) break;
    }

    const phase = resolvePhase(economy, defaultConfig);
    expect(['recovery', 'rising']).toContain(phase);
  });
});
