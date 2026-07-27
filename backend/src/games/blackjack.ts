import { v4 as uuid } from 'uuid';
import { getDb } from '../db.js';
import {
  applyBetResult,
  decideOutcome,
  type EconomyConfig,
  type UserEconomy,
} from '../economy/engine.js';
import {
  cardValue,
  generateHandForOutcome,
  handTotal,
  randomCard,
  type Card,
} from './blackjack-logic.js';

function getConfig(): EconomyConfig {
  return getDb().prepare('SELECT * FROM economy_config WHERE id = 1').get() as EconomyConfig;
}

function getEconomy(userId: string): UserEconomy {
  return getDb()
    .prepare('SELECT * FROM user_economy WHERE user_id = ?')
    .get(userId) as UserEconomy;
}

interface SessionRow {
  id: string;
  user_id: string;
  bet_amount: number;
  player_cards: string;
  dealer_cards: string;
  status: string;
  target_outcome: string | null;
}

function parseCards(json: string): Card[] {
  return JSON.parse(json);
}

export function startBlackjack(userId: string, bet: number) {
  if (bet < 100) throw new Error('Minimum bet is 100');
  const economy = getEconomy(userId);
  if (economy.balance < bet) throw new Error('Insufficient balance');

  const config = getConfig();
  let seed = Date.now();
  const rng = () => {
    seed = (seed * 16807 + 1) % 2147483647;
    return seed / 2147483647;
  };

  const decision = decideOutcome(economy, bet, config, rng);
  const target = decision.shouldWin ? 'win' : rng() < 0.1 ? 'push' : 'lose';
  const { player, dealer } = generateHandForOutcome(target, rng);

  const sessionId = uuid();
  const db = getDb();
  db.prepare(
    `INSERT INTO blackjack_sessions (id, user_id, bet_amount, player_cards, dealer_cards, status, target_outcome)
     VALUES (?, ?, ?, ?, ?, 'active', ?)`
  ).run(sessionId, userId, bet, JSON.stringify(player), JSON.stringify([dealer[0]]), target);

  return {
    sessionId,
    bet,
    playerCards: player,
    dealerCards: [dealer[0]],
    dealerHidden: true,
    playerTotal: handTotal(player),
    canHit: handTotal(player) < 21,
  };
}

export function blackjackAction(userId: string, sessionId: string, action: 'hit' | 'stand') {
  const db = getDb();
  const session = db
    .prepare('SELECT * FROM blackjack_sessions WHERE id = ? AND user_id = ?')
    .get(sessionId, userId) as SessionRow | undefined;

  if (!session || session.status !== 'active') throw new Error('Invalid session');

  let player = parseCards(session.player_cards);
  let dealer = parseCards(session.dealer_cards);
  const hiddenDealer = db
    .prepare('SELECT dealer_cards FROM blackjack_sessions WHERE id = ?')
    .get(sessionId);
  const fullDealerRow = db
    .prepare('SELECT * FROM blackjack_sessions WHERE id = ?')
    .get(sessionId) as SessionRow;

  let seed = Date.now();
  const rng = () => {
    seed = (seed * 16807 + 1) % 2147483647;
    return seed / 2147483647;
  };

  if (action === 'hit') {
    player.push(randomCard(rng));
    const total = handTotal(player);
    if (total > 21) {
      return finishSession(session, player, fullDealerRow, 'lose', userId);
    }
    db.prepare('UPDATE blackjack_sessions SET player_cards = ? WHERE id = ?').run(
      JSON.stringify(player),
      sessionId
    );
    return {
      sessionId,
      playerCards: player,
      dealerCards: dealer,
      dealerHidden: true,
      playerTotal: total,
      canHit: total < 21,
      status: 'active',
    };
  }

  const generated = generateHandForOutcome(
    (session.target_outcome as 'win' | 'lose' | 'push') ?? 'lose',
    rng
  );
  dealer = generated.dealer;

  while (handTotal(dealer) < 17) {
    dealer.push(randomCard(rng));
  }

  const pTotal = handTotal(player);
  const dTotal = handTotal(dealer);
  let outcome: 'win' | 'lose' | 'push';
  if (pTotal > 21) outcome = 'lose';
  else if (dTotal > 21) outcome = 'win';
  else if (pTotal > dTotal) outcome = 'win';
  else if (pTotal < dTotal) outcome = 'lose';
  else outcome = 'push';

  return finishSession(session, player, { ...fullDealerRow, dealer_cards: JSON.stringify(dealer) }, outcome, userId);
}

function finishSession(
  session: SessionRow,
  player: Card[],
  fullRow: SessionRow,
  outcome: 'win' | 'lose' | 'push',
  userId: string
) {
  const db = getDb();
  const economy = getEconomy(userId);
  const bet = session.bet_amount;
  let payout = 0;
  if (outcome === 'win') payout = bet * 2;
  else if (outcome === 'push') payout = bet;

  const config = getConfig();
  const decision = decideOutcome(economy, bet, config);
  const updated = applyBetResult(economy, bet, payout, config);

  db.transaction(() => {
    db.prepare('UPDATE blackjack_sessions SET status = ?, dealer_cards = ? WHERE id = ?').run(
      'finished',
      fullRow.dealer_cards,
      session.id
    );
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
       VALUES (?, ?, 'blackjack', ?, ?, ?, ?, ?)`
    ).run(
      uuid(),
      userId,
      bet,
      payout,
      updated.balance,
      decision.phase,
      JSON.stringify({ outcome })
    );
  })();

  const dealer = parseCards(fullRow.dealer_cards);
  return {
    sessionId: session.id,
    playerCards: player,
    dealerCards: dealer,
    dealerHidden: false,
    playerTotal: handTotal(player),
    dealerTotal: handTotal(dealer),
    outcome,
    payout,
    balance: updated.balance,
    status: 'finished',
  };
}
