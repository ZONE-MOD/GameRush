-- Cloudflare D1 schema proposal for Dino Rush.
-- Apply only after reviewing and deploying the Worker API.
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS players (
  player_id INTEGER PRIMARY KEY CHECK (player_id BETWEEN 100000 AND 999999),
  username TEXT NOT NULL,
  username_normalized TEXT NOT NULL UNIQUE,
  phone_e164 TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  is_verified INTEGER NOT NULL DEFAULT 0 CHECK (is_verified IN (0,1)),
  coins INTEGER NOT NULL DEFAULT 500 CHECK (coins >= 0),
  max_level INTEGER NOT NULL DEFAULT 1 CHECK (max_level BETWEEN 1 AND 10),
  banned_until TEXT DEFAULT NULL,
  ban_reason TEXT DEFAULT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- A name remains reserved even if an account is later disabled/deleted.
CREATE TABLE IF NOT EXISTS reserved_names (
  username_normalized TEXT PRIMARY KEY,
  player_id INTEGER NOT NULL,
  reserved_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(player_id) REFERENCES players(player_id)
);

CREATE TABLE IF NOT EXISTS coin_ledger (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  player_id INTEGER NOT NULL,
  delta INTEGER NOT NULL,
  reason TEXT NOT NULL,
  actor_admin TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(player_id) REFERENCES players(player_id)
);

CREATE TABLE IF NOT EXISTS admin_audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  actor_admin TEXT NOT NULL,
  action TEXT NOT NULL,
  target_player_id INTEGER,
  details_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_players_username ON players(username_normalized);
CREATE INDEX IF NOT EXISTS idx_coin_ledger_player ON coin_ledger(player_id, created_at);
CREATE INDEX IF NOT EXISTS idx_players_ban ON players(banned_until);
