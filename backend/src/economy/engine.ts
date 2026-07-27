export interface EconomyConfig {
  initial_balance: number;
  ceiling_multiplier: number;
  floor_multiplier: number;
  win_rate_rising: number;
  win_rate_falling: number;
  win_rate_neutral: number;
  big_bet_ratio: number;
  small_bet_ratio: number;
  post_peak_big_bet_loss_rate: number;
}

export type EconomyPhase = 'rising' | 'falling' | 'recovery';

export interface UserEconomy {
  user_id: string;
  balance: number;
  initial_balance: number;
  peak_balance: number;
  phase: EconomyPhase;
  session_wins: number;
  session_losses: number;
  last_bet_at: string | null;
  total_bets: number;
  last_daily_bonus_at: string | null;
}

export interface OutcomeDecision {
  shouldWin: boolean;
  winProbability: number;
  phase: EconomyPhase;
  multiplierMin: number;
  multiplierMax: number;
  tier: 'bronze' | 'silver' | 'gold' | 'diamond';
}

export function getEconomyConfig(config: EconomyConfig) {
  return {
    ceiling: config.initial_balance * config.ceiling_multiplier,
    floor: config.initial_balance * config.floor_multiplier,
    ...config,
  };
}

export function resolvePhase(
  economy: UserEconomy,
  config: EconomyConfig
): EconomyPhase {
  const { ceiling, floor } = getEconomyConfig(config);
  let phase = economy.phase;

  if (economy.balance >= ceiling * 0.9) {
    phase = 'falling';
  } else if (economy.balance <= floor) {
    phase = 'recovery';
  } else if (phase === 'recovery') {
    phase = 'rising';
  } else if (phase === 'rising' && economy.balance < ceiling * 0.85) {
    phase = 'rising';
  }

  return phase;
}

export function decideOutcome(
  economy: UserEconomy,
  betAmount: number,
  config: EconomyConfig,
  rng: () => number = Math.random
): OutcomeDecision {
  const ec = getEconomyConfig(config);
  const phase = resolvePhase(economy, config);
  const betRatio = betAmount / Math.max(economy.balance, 1);

  let winProbability: number;
  let multiplierMin: number;
  let multiplierMax: number;
  let tier: OutcomeDecision['tier'] = 'bronze';

  const postPeak = economy.peak_balance >= ec.ceiling * 0.7;

  if (postPeak && betRatio >= config.big_bet_ratio) {
    winProbability = 1 - config.post_peak_big_bet_loss_rate;
    multiplierMin = 0;
    multiplierMax = 0.8;
    tier = 'bronze';
  } else if (postPeak && betRatio <= config.small_bet_ratio) {
    winProbability = 0.65;
    multiplierMin = 1.2;
    multiplierMax = 2.0;
    tier = 'silver';
  } else {
    switch (phase) {
      case 'rising':
        winProbability = config.win_rate_rising;
        multiplierMin = 1.2;
        multiplierMax = 2.5;
        tier = betRatio < 0.03 ? 'silver' : 'bronze';
        break;
      case 'falling':
        winProbability = config.win_rate_falling;
        multiplierMin = 0;
        multiplierMax = 0.8;
        tier = 'bronze';
        break;
      case 'recovery':
        winProbability = config.win_rate_rising;
        multiplierMin = 1.5;
        multiplierMax = 3.0;
        tier = 'silver';
        break;
      default:
        winProbability = config.win_rate_neutral;
        multiplierMin = 0.5;
        multiplierMax = 1.5;
        tier = 'bronze';
    }
  }

  const shouldWin = rng() < winProbability;

  if (shouldWin && phase === 'rising' && rng() < 0.05) {
    tier = 'gold';
    multiplierMin = 5;
    multiplierMax = 15;
  }

  return {
    shouldWin,
    winProbability,
    phase,
    multiplierMin,
    multiplierMax,
    tier,
  };
}

export function calculatePayout(
  betAmount: number,
  decision: OutcomeDecision,
  rng: () => number = Math.random
): number {
  if (!decision.shouldWin) {
    if (decision.multiplierMax <= 0.8 && rng() < 0.5) {
      return Math.floor(betAmount * decision.multiplierMax);
    }
    return 0;
  }

  const mult =
    decision.multiplierMin +
    rng() * (decision.multiplierMax - decision.multiplierMin);
  return Math.floor(betAmount * mult);
}

export function applyBetResult(
  economy: UserEconomy,
  betAmount: number,
  payout: number,
  config: EconomyConfig
): UserEconomy {
  const newBalance = economy.balance - betAmount + payout;
  const updated: UserEconomy = {
    ...economy,
    balance: newBalance,
    peak_balance: Math.max(economy.peak_balance, newBalance),
    session_wins: payout > betAmount ? economy.session_wins + 1 : economy.session_wins,
    session_losses: payout < betAmount ? economy.session_losses + 1 : economy.session_losses,
    total_bets: economy.total_bets + 1,
    last_bet_at: new Date().toISOString(),
    phase: economy.phase,
  };
  return { ...updated, phase: resolvePhase(updated, config) };
}
