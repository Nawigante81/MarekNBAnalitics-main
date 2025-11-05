/*
  # Create odds table
  
  1. New Tables
    - `odds`
      - `id` (uuid, primary key, auto-generated)
      - `game_id` (text, foreign key to games.id)
      - `bookmaker_key` (text) - identifier like "draftkings"
      - `bookmaker_title` (text) - display name like "DraftKings"
      - `last_update` (timestamp) - when odds were last updated
      - `market_type` (text) - "h2h", "spread", or "totals"
      - `team` (text) - team name (for h2h and spread)
      - `outcome_name` (text) - outcome name (for totals: "Over", "Under")
      - `point` (numeric) - spread/total line
      - `price` (numeric) - odds/price
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
  
  2. Indexes
    - Index on `game_id` for game lookups
    - Index on `bookmaker_key` for bookmaker analysis
*/

CREATE TABLE IF NOT EXISTS public.odds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id text NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
  bookmaker_key text NOT NULL,
  bookmaker_title text,
  last_update timestamptz,
  market_type text NOT NULL,
  team text,
  outcome_name text,
  point numeric,
  price numeric,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_odds_game_id ON public.odds(game_id);
CREATE INDEX IF NOT EXISTS idx_odds_bookmaker_key ON public.odds(bookmaker_key);
CREATE INDEX IF NOT EXISTS idx_odds_market_type ON public.odds(market_type);
