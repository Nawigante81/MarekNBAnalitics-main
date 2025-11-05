/*
  # Create games table
  
  1. New Tables
    - `games`
      - `id` (text, primary key) - unique game ID from API
      - `sport_key` (text)
      - `sport_title` (text)
      - `commence_time` (timestamp)
      - `home_team` (text) - home team name
      - `away_team` (text) - away team name
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
*/

CREATE TABLE IF NOT EXISTS public.games (
  id text PRIMARY KEY,
  sport_key text,
  sport_title text,
  commence_time timestamptz NOT NULL,
  home_team text NOT NULL,
  away_team text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_games_commence_time ON public.games(commence_time);
