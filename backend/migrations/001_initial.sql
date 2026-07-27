-- HappyGamba schema (SQLite-compatible)

CREATE TABLE IF NOT EXISTS economy_config (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  initial_balance INTEGER NOT NULL DEFAULT 30000,
  ceiling_multiplier REAL NOT NULL DEFAULT 5.0,
  floor_multiplier REAL NOT NULL DEFAULT 1.0,
  win_rate_rising REAL NOT NULL DEFAULT 0.80,
  win_rate_falling REAL NOT NULL DEFAULT 0.25,
  win_rate_neutral REAL NOT NULL DEFAULT 0.55,
  big_bet_ratio REAL NOT NULL DEFAULT 0.10,
  small_bet_ratio REAL NOT NULL DEFAULT 0.05,
  post_peak_big_bet_loss_rate REAL NOT NULL DEFAULT 0.92
);

INSERT OR IGNORE INTO economy_config (id) VALUES (1);

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL COLLATE NOCASE UNIQUE,
  password_hash TEXT,
  auth_provider TEXT NOT NULL DEFAULT 'password' CHECK (auth_provider IN ('password', 'google', 'apple')),
  firebase_uid TEXT UNIQUE,
  avatar_url TEXT,
  is_vip INTEGER NOT NULL DEFAULT 0,
  is_ad_free INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS user_economy (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  balance INTEGER NOT NULL,
  initial_balance INTEGER NOT NULL,
  peak_balance INTEGER NOT NULL,
  phase TEXT NOT NULL DEFAULT 'rising' CHECK (phase IN ('rising', 'falling', 'recovery')),
  session_wins INTEGER NOT NULL DEFAULT 0,
  session_losses INTEGER NOT NULL DEFAULT 0,
  last_bet_at TEXT,
  total_bets INTEGER NOT NULL DEFAULT 0,
  last_daily_bonus_at TEXT
);

CREATE TABLE IF NOT EXISTS bet_history (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  game_type TEXT NOT NULL,
  bet_amount INTEGER NOT NULL,
  payout INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,
  phase TEXT NOT NULL,
  metadata TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS purchases (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  product_id TEXT NOT NULL,
  coins_granted INTEGER NOT NULL DEFAULT 0,
  revenuecat_event_id TEXT UNIQUE,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS blackjack_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  bet_amount INTEGER NOT NULL,
  player_cards TEXT NOT NULL,
  dealer_cards TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  target_outcome TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_bet_history_user ON bet_history(user_id);
CREATE INDEX IF NOT EXISTS idx_users_firebase ON users(firebase_uid);
