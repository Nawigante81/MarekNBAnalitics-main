/*
  # Create teams table
  
  1. New Tables
    - `teams`
      - `id` (uuid, primary key, auto-generated)
      - `abbreviation` (text, unique) - e.g., "CHI", "LAL"
      - `full_name` (text) - full team name
      - `name` (text) - team nickname
      - `city` (text) - team city
      - `created_at` (timestamp)
  
  2. Indexes
    - Index on `abbreviation` for fast lookups
*/

CREATE TABLE IF NOT EXISTS public.teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  abbreviation text UNIQUE NOT NULL,
  full_name text NOT NULL,
  name text NOT NULL,
  city text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_teams_abbreviation ON public.teams(abbreviation);
