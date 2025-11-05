-- =====================================================
-- SUPABASE RLS POLICIES FOR NBA ANALYTICS APPLICATION
-- =====================================================
-- Run this SQL in Supabase SQL Editor to enable public access to all tables
-- These policies allow unrestricted read/write access for the analytics application

-- =====================================================
-- 1. TEAMS TABLE POLICIES
-- =====================================================

-- Enable RLS on teams table
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public read access for teams" ON teams;
DROP POLICY IF EXISTS "Public insert access for teams" ON teams;
DROP POLICY IF EXISTS "Public update access for teams" ON teams;
DROP POLICY IF EXISTS "Public delete access for teams" ON teams;

-- Allow public read access to teams
CREATE POLICY "Public read access for teams" 
ON teams FOR SELECT 
USING (true);

-- Allow public insert access for teams (for scraping)
CREATE POLICY "Public insert access for teams" 
ON teams FOR INSERT 
WITH CHECK (true);

-- Allow public update access for teams
CREATE POLICY "Public update access for teams" 
ON teams FOR UPDATE 
USING (true) 
WITH CHECK (true);

-- Allow public delete access for teams (if needed for cleanup)
CREATE POLICY "Public delete access for teams" 
ON teams FOR DELETE 
USING (true);

-- =====================================================
-- 2. GAMES TABLE POLICIES
-- =====================================================

-- Enable RLS on games table
ALTER TABLE games ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public read access for games" ON games;
DROP POLICY IF EXISTS "Public insert access for games" ON games;
DROP POLICY IF EXISTS "Public update access for games" ON games;
DROP POLICY IF EXISTS "Public delete access for games" ON games;

-- Allow public read access to games
CREATE POLICY "Public read access for games" 
ON games FOR SELECT 
USING (true);

-- Allow public insert access for games (for scraping)
CREATE POLICY "Public insert access for games" 
ON games FOR INSERT 
WITH CHECK (true);

-- Allow public update access for games
CREATE POLICY "Public update access for games" 
ON games FOR UPDATE 
USING (true) 
WITH CHECK (true);

-- Allow public delete access for games
CREATE POLICY "Public delete access for games" 
ON games FOR DELETE 
USING (true);

-- =====================================================
-- 3. ODDS TABLE POLICIES
-- =====================================================

-- Enable RLS on odds table
ALTER TABLE odds ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public read access for odds" ON odds;
DROP POLICY IF EXISTS "Public insert access for odds" ON odds;
DROP POLICY IF EXISTS "Public update access for odds" ON odds;
DROP POLICY IF EXISTS "Public delete access for odds" ON odds;

-- Allow public read access to odds
CREATE POLICY "Public read access for odds" 
ON odds FOR SELECT 
USING (true);

-- Allow public insert access for odds (for scraping)
CREATE POLICY "Public insert access for odds" 
ON odds FOR INSERT 
WITH CHECK (true);

-- Allow public update access for odds
CREATE POLICY "Public update access for odds" 
ON odds FOR UPDATE 
USING (true) 
WITH CHECK (true);

-- Allow public delete access for odds
CREATE POLICY "Public delete access for odds" 
ON odds FOR DELETE 
USING (true);

-- =====================================================
-- 4. PLAYERS TABLE POLICIES
-- =====================================================

-- Enable RLS on players table
ALTER TABLE players ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public read access for players" ON players;
DROP POLICY IF EXISTS "Public insert access for players" ON players;
DROP POLICY IF EXISTS "Public update access for players" ON players;
DROP POLICY IF EXISTS "Public delete access for players" ON players;

-- Allow public read access to players
CREATE POLICY "Public read access for players" 
ON players FOR SELECT 
USING (true);

-- Allow public insert access for players (for scraping)
CREATE POLICY "Public insert access for players" 
ON players FOR INSERT 
WITH CHECK (true);

-- Allow public update access for players
CREATE POLICY "Public update access for players" 
ON players FOR UPDATE 
USING (true) 
WITH CHECK (true);

-- Allow public delete access for players
CREATE POLICY "Public delete access for players" 
ON players FOR DELETE 
USING (true);

-- =====================================================
-- 5. CREATE PLAYERS TABLE (if not exists)
-- =====================================================

CREATE TABLE IF NOT EXISTS players (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Player identification
    name TEXT NOT NULL,
    jersey_number INTEGER,
    
    -- Team relationship
    team_id UUID REFERENCES teams(id) ON DELETE SET NULL,
    team_abbreviation TEXT NOT NULL, -- For easier queries
    
    -- Player details
    position TEXT,
    height TEXT, -- e.g., "6-6" format from Basketball-Reference
    weight INTEGER, -- in pounds
    birth_date DATE,
    experience INTEGER, -- years in NBA
    college TEXT,
    
    -- Basketball-Reference specific data
    basketball_reference_id TEXT UNIQUE, -- e.g., "jamesle01" 
    basketball_reference_url TEXT,
    
    -- Status and metadata
    is_active BOOLEAN DEFAULT true,
    season_year TEXT DEFAULT '2024-25', -- Track which season this data is for
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure no duplicate players per team in same season
    UNIQUE(name, team_abbreviation, season_year)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_players_team_id ON players(team_id);
CREATE INDEX IF NOT EXISTS idx_players_team_abbreviation ON players(team_abbreviation);
CREATE INDEX IF NOT EXISTS idx_players_name ON players(name);
CREATE INDEX IF NOT EXISTS idx_players_basketball_reference_id ON players(basketball_reference_id);
CREATE INDEX IF NOT EXISTS idx_players_active ON players(is_active);
CREATE INDEX IF NOT EXISTS idx_players_season ON players(season_year);

-- Create updated_at trigger for players table
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop existing trigger if it exists, then create new one
DROP TRIGGER IF EXISTS update_players_updated_at ON players;

CREATE TRIGGER update_players_updated_at 
    BEFORE UPDATE ON players 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 6. VIEWS HANDLING (for views like best_odds_per_game)
-- =====================================================

-- Views automatically inherit RLS policies from their base tables
-- Since we enabled RLS on teams, games, and odds tables with public access policies,
-- the views should work automatically without additional configuration.

-- If views still show "Unrestricted" status in Supabase UI, that's normal and expected.
-- Views cannot have RLS enabled directly - they inherit access control from underlying tables.

-- Test that views work properly:
-- SELECT * FROM best_odds_per_game LIMIT 3;
-- SELECT * FROM current_games_with_odds LIMIT 3;

-- =====================================================
-- 7. VERIFICATION QUERIES
-- =====================================================

-- Run these to verify policies are working:
-- SELECT * FROM teams LIMIT 5;
-- SELECT * FROM games LIMIT 5;
-- SELECT * FROM odds LIMIT 5; 
-- SELECT * FROM players LIMIT 5;

-- =====================================================
-- 8. ALTERNATIVE OPTIONS
-- =====================================================

-- OPTION A: Disable RLS on views only (recommended for analytics views)
-- ALTER TABLE best_odds_per_game DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE current_games_with_odds DISABLE ROW LEVEL SECURITY;

-- OPTION B: Disable RLS completely on all tables (less secure but simpler):
-- ALTER TABLE teams DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE games DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE odds DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE players DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE best_odds_per_game DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE current_games_with_odds DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- NOTES:
-- =====================================================
-- 1. These policies allow public access - suitable for analytics app
-- 2. For production, consider more restrictive policies based on authentication
-- 3. Views (best_odds_per_game, current_games_with_odds) will work automatically
-- 4. The anon key in your .env should work with these policies
-- 5. If you still get permission errors, check your Supabase project settings