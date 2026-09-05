-- backend/schema.sql
-- CampusSetu PostgreSQL Schema (Phase 1)
-- Run once: psql -U postgres -d campussetu -f schema.sql

-- ── Extensions ────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- for ILIKE trigram index

-- ─────────────────────────────────────────────────────────
-- USERS
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid     TEXT UNIQUE NOT NULL,
  email            TEXT UNIQUE NOT NULL,
  name             TEXT NOT NULL DEFAULT '',
  photo_url        TEXT,
  college          TEXT,
  state            TEXT,
  city             TEXT,
  course           TEXT,       -- B.Tech, M.Tech, MBA, etc.
  branch           TEXT,       -- CS, Mechanical, etc.
  year_of_study    SMALLINT CHECK (year_of_study BETWEEN 1 AND 7),
  bio              TEXT CHECK (char_length(bio) <= 300),
  skills           TEXT[]      DEFAULT '{}',
  profile_complete BOOLEAN     DEFAULT false,
  is_verified      BOOLEAN     DEFAULT false,
  is_premium       BOOLEAN     DEFAULT false,
  is_banned        BOOLEAN     DEFAULT false,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users (firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_state_city   ON users (state, city);
CREATE INDEX IF NOT EXISTS idx_users_skills        ON users USING GIN (skills);

-- ─────────────────────────────────────────────────────────
-- CONNECTIONS
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS connections (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status       TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected')),
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (requester_id, receiver_id)
);

CREATE INDEX IF NOT EXISTS idx_connections_receiver ON connections (receiver_id, status);

-- ─────────────────────────────────────────────────────────
-- POSTS
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS posts (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content     TEXT NOT NULL CHECK (char_length(content) <= 2000),
  image_url   TEXT,
  is_deleted  BOOLEAN     DEFAULT false,
  is_pinned   BOOLEAN     DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_posts_author     ON posts (author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts (created_at DESC);

CREATE TABLE IF NOT EXISTS post_likes (
  post_id    UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (post_id, user_id)
);

CREATE TABLE IF NOT EXISTS post_comments (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id    UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content    TEXT NOT NULL CHECK (char_length(content) <= 500),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────
-- TSHARE
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tshares (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code           TEXT UNIQUE NOT NULL,
  content        TEXT NOT NULL,
  language       TEXT DEFAULT 'text',
  uploader_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  retrieve_count INT  DEFAULT 0,
  expires_at     TIMESTAMPTZ NOT NULL,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- CREATE INDEX IF NOT EXISTS idx_tshares_code ON tshares (code) WHERE expires_at > NOW();

-- ─────────────────────────────────────────────────────────
-- NOTES
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notes (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title          TEXT NOT NULL,
  subject        TEXT NOT NULL,
  file_url       TEXT NOT NULL,
  file_size_mb   NUMERIC(6,2),
  uploader_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  download_count INT  DEFAULT 0,
  is_approved    BOOLEAN DEFAULT false,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notes_subject     ON notes (subject);
CREATE INDEX IF NOT EXISTS idx_notes_approved    ON notes (is_approved, download_count DESC);

-- ─────────────────────────────────────────────────────────
-- JOBS / OPPORTUNITIES
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS jobs (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title       TEXT NOT NULL,
  company     TEXT NOT NULL,
  description TEXT,
  type        TEXT CHECK (type IN ('Internship','Full-Time','Part-Time','Freelance','Research')),
  state       TEXT,
  city        TEXT,
  is_remote   BOOLEAN DEFAULT false,
  apply_url   TEXT,
  deadline    DATE,
  poster_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_approved BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_jobs_type_state ON jobs (type, state, is_approved);

-- ─────────────────────────────────────────────────────────
-- PRODUCTS (Marketplace)
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title       TEXT NOT NULL,
  description TEXT,
  price       NUMERIC(10,2) NOT NULL,
  category    TEXT NOT NULL,
  image_url   TEXT,
  seller_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status      TEXT DEFAULT 'active' CHECK (status IN ('active','sold','removed')),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_category ON products (category, status);

-- ─────────────────────────────────────────────────────────
-- REPORTS
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reports (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_type       TEXT CHECK (target_type IN ('post','user','product','note')),
  target_id         UUID,
  reported_user_id  UUID REFERENCES users(id) ON DELETE CASCADE,
  reason            TEXT NOT NULL,
  status            TEXT DEFAULT 'pending' CHECK (status IN ('pending','resolved')),
  resolution        TEXT,
  resolved_at       TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────
-- POINTS LEDGER
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS points_ledger (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount      INT NOT NULL,
  reason      TEXT NOT NULL, -- 'note_upload', 'connection_made', etc.
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_points_user ON points_ledger (user_id);

-- ─────────────────────────────────────────────────────────
-- STARTUPS
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS startups (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT NOT NULL,
  tagline     TEXT NOT NULL,
  description TEXT,
  sector      TEXT,
  stage       TEXT CHECK (stage IN ('Ideation','MVP','Pre-Revenue','Revenue','Scaling')),
  founder_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  team_size   INT DEFAULT 1,
  looking_for INT DEFAULT 0,
  is_approved BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────
-- STARTUP TEAM MEMBERS
-- ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS startup_members (
  startup_id UUID NOT NULL REFERENCES startups(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role       TEXT DEFAULT 'Member',
  joined_at  TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (startup_id, user_id)
);
