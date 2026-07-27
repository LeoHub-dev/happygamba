import Database from 'better-sqlite3';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

let db: Database.Database | null = null;

export function getDb(): Database.Database {
  if (!db) {
    const dataDir = path.join(__dirname, '..', 'data');
    if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });
    const dbPath = process.env.DATABASE_PATH ?? path.join(dataDir, 'happygamba.db');
    db = new Database(dbPath);
    db.pragma('journal_mode = WAL');
    db.pragma('foreign_keys = ON');
    runMigrations(db);
  }
  return db;
}

function runMigrations(database: Database.Database) {
  const migrationPath = path.join(__dirname, '..', 'migrations', '001_initial.sql');
  const sql = fs.readFileSync(migrationPath, 'utf-8');
  database.exec(sql);
}

export function closeDb() {
  db?.close();
  db = null;
}
