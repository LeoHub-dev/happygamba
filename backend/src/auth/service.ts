import bcrypt from 'bcryptjs';
import { v4 as uuid } from 'uuid';
import { getDb } from '../db.js';
import { signToken } from './jwt.js';
import type { EconomyConfig } from '../economy/engine.js';

const USERNAME_RE = /^[a-zA-Z0-9_]{3,20}$/;

function getConfig(): EconomyConfig {
  const db = getDb();
  return db.prepare('SELECT * FROM economy_config WHERE id = 1').get() as EconomyConfig;
}

function createUserEconomy(userId: string) {
  const config = getConfig();
  const db = getDb();
  db.prepare(
    `INSERT INTO user_economy (user_id, balance, initial_balance, peak_balance, phase)
     VALUES (?, ?, ?, ?, 'rising')`
  ).run(userId, config.initial_balance, config.initial_balance, config.initial_balance);
}

export function registerUser(username: string, password: string) {
  if (!USERNAME_RE.test(username)) {
    throw new Error('Username must be 3-20 alphanumeric characters or underscores');
  }
  if (password.length < 6) {
    throw new Error('Password must be at least 6 characters');
  }

  const db = getDb();
  const existing = db
    .prepare('SELECT id FROM users WHERE username = ? COLLATE NOCASE')
    .get(username);
  if (existing) throw new Error('Username already exists');

  const id = uuid();
  const passwordHash = bcrypt.hashSync(password, 10);
  db.prepare(
    `INSERT INTO users (id, username, password_hash, auth_provider) VALUES (?, ?, ?, 'password')`
  ).run(id, username, passwordHash);
  createUserEconomy(id);

  const token = signToken({ userId: id, username });
  return { token, user: { id, username, auth_provider: 'password' } };
}

export function loginUser(username: string, password: string) {
  const db = getDb();
  const user = db
    .prepare('SELECT * FROM users WHERE username = ? COLLATE NOCASE')
    .get(username) as {
    id: string;
    username: string;
    password_hash: string | null;
    auth_provider: string;
  } | undefined;

  if (!user || !user.password_hash) {
    throw new Error('Invalid credentials');
  }
  if (!bcrypt.compareSync(password, user.password_hash)) {
    throw new Error('Invalid credentials');
  }

  const token = signToken({ userId: user.id, username: user.username });
  return {
    token,
    user: { id: user.id, username: user.username, auth_provider: user.auth_provider },
  };
}

export function syncSocialUser(
  firebaseUid: string,
  displayName: string,
  provider: 'google' | 'apple',
  avatarUrl?: string
) {
  const db = getDb();
  let user = db
    .prepare('SELECT * FROM users WHERE firebase_uid = ?')
    .get(firebaseUid) as { id: string; username: string; auth_provider: string } | undefined;

  if (!user) {
    const id = uuid();
    const baseUsername = displayName
      .replace(/[^a-zA-Z0-9_]/g, '')
      .slice(0, 15) || `user_${firebaseUid.slice(0, 8)}`;
    let username = baseUsername;
    let suffix = 1;
    while (db.prepare('SELECT id FROM users WHERE username = ? COLLATE NOCASE').get(username)) {
      username = `${baseUsername.slice(0, 12)}_${suffix++}`;
    }

    db.prepare(
      `INSERT INTO users (id, username, auth_provider, firebase_uid, avatar_url)
       VALUES (?, ?, ?, ?, ?)`
    ).run(id, username, provider, firebaseUid, avatarUrl ?? null);
    createUserEconomy(id);
    user = { id, username, auth_provider: provider };
  }

  const token = signToken({ userId: user.id, username: user.username });
  return { token, user: { id: user.id, username: user.username, auth_provider: user.auth_provider } };
}

export function getUserProfile(userId: string) {
  const db = getDb();
  const row = db
    .prepare(
      `SELECT u.id, u.username, u.auth_provider, u.avatar_url, u.is_vip, u.is_ad_free,
              e.balance, e.phase, e.peak_balance, e.initial_balance
       FROM users u
       JOIN user_economy e ON e.user_id = u.id
       WHERE u.id = ?`
    )
    .get(userId);

  if (!row) throw new Error('User not found');
  return row;
}
