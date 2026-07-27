import type Database from 'better-sqlite3';
import { getDb } from '../db.js';

type Stmt = Database.Statement;

let stmts: {
  getEconomy: Stmt;
  getConfig: Stmt;
  updateEconomy: Stmt;
  insertBet: Stmt;
} | null = null;

function ensure() {
  if (stmts) return stmts;
  const db = getDb();
  stmts = {
    getEconomy: db.prepare('SELECT * FROM user_economy WHERE user_id = ?'),
    getConfig: db.prepare('SELECT * FROM economy_config WHERE id = 1'),
    updateEconomy: db.prepare(
      `UPDATE user_economy SET balance=?, peak_balance=?, phase=?, session_wins=?, session_losses=?,
       total_bets=?, last_bet_at=? WHERE user_id=?`
    ),
    insertBet: db.prepare(
      `INSERT INTO bet_history (id, user_id, game_type, bet_amount, payout, balance_after, phase, metadata)
       VALUES (?, ?, 'slots', ?, ?, ?, ?, ?)`
    ),
  };
  return stmts;
}

export function slotsStatements() {
  return ensure();
}
