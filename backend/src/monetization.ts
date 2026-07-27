import { v4 as uuid } from 'uuid';
import { getDb } from './db.js';
import { getUserProfile } from './auth/service.js';

const COIN_PRODUCTS: Record<string, number> = {
  coins_50k: 50000,
  coins_200k: 200000,
  coins_1m: 1000000,
};

export function handleRevenueCatWebhook(body: {
  event?: {
    id?: string;
    type?: string;
    app_user_id?: string;
    product_id?: string;
    entitlement_ids?: string[];
  };
}) {
  const event = body.event;
  if (!event?.app_user_id) return { ok: true };

  const db = getDb();
  const userId = event.app_user_id;

  if (event.id) {
    const existing = db
      .prepare('SELECT id FROM purchases WHERE revenuecat_event_id = ?')
      .get(event.id);
    if (existing) return { ok: true, duplicate: true };
  }

  const user = db.prepare('SELECT id FROM users WHERE id = ?').get(userId);
  if (!user) return { ok: false, error: 'User not found' };

  db.transaction(() => {
    if (event.product_id && COIN_PRODUCTS[event.product_id]) {
      const coins = COIN_PRODUCTS[event.product_id];
      db.prepare('UPDATE user_economy SET balance = balance + ? WHERE user_id = ?').run(
        coins,
        userId
      );
      db.prepare(
        `INSERT INTO purchases (id, user_id, product_id, coins_granted, revenuecat_event_id)
         VALUES (?, ?, ?, ?, ?)`
      ).run(uuid(), userId, event.product_id, coins, event.id ?? null);
    }

    const entitlements = event.entitlement_ids ?? [];
    if (entitlements.includes('ad_free') || event.product_id === 'happygamba_ad_free') {
      db.prepare('UPDATE users SET is_ad_free = 1 WHERE id = ?').run(userId);
    }
    if (entitlements.includes('vip') || event.product_id === 'happygamba_vip') {
      db.prepare('UPDATE users SET is_vip = 1, is_ad_free = 1 WHERE id = ?').run(userId);
    }
  })();

  return { ok: true };
}

export function claimDailyBonus(userId: string, rewarded = false) {
  const db = getDb();
  const economy = db
    .prepare('SELECT * FROM user_economy WHERE user_id = ?')
    .get(userId) as { last_daily_bonus_at: string | null; balance: number };
  const profile = getUserProfile(userId) as { is_vip: number };

  const now = new Date();
  if (economy.last_daily_bonus_at) {
    const last = new Date(economy.last_daily_bonus_at);
    const hoursSince = (now.getTime() - last.getTime()) / (1000 * 60 * 60);
    if (!rewarded && hoursSince < 20) {
      throw new Error('Daily bonus already claimed');
    }
    if (rewarded && hoursSince < 4) {
      throw new Error('Rewarded bonus on cooldown');
    }
  }

  const baseBonus = profile.is_vip ? 10000 : 5000;
  const bonus = rewarded ? baseBonus : baseBonus;

  db.prepare(
    'UPDATE user_economy SET balance = balance + ?, last_daily_bonus_at = ? WHERE user_id = ?'
  ).run(bonus, now.toISOString(), userId);

  const updated = getUserProfile(userId);
  return { bonus, balance: (updated as { balance: number }).balance };
}

export function getLiveBetsFeed() {
  const names = ['LuckyFox', 'GoldRush', 'SpinKing', 'CoinHunter', 'VIP_Player', 'MegaWin'];
  const feed = [];
  for (let i = 0; i < 8; i++) {
    feed.push({
      username: names[Math.floor(Math.random() * names.length)] + '***',
      bet: [500, 1000, 2000, 5000][Math.floor(Math.random() * 4)],
      multiplier: (1 + Math.random() * 10).toFixed(2),
      payout: Math.floor(500 + Math.random() * 50000),
      game: Math.random() > 0.5 ? 'slots' : 'blackjack',
    });
  }
  return feed;
}
