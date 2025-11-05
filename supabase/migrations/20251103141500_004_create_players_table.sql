-- Create players table to store NBA player rosters
-- This table will link to the teams table and store detailed player information

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

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_players_updated_at 
    BEFORE UPDATE ON players 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Add some useful comments
COMMENT ON TABLE players IS 'NBA player rosters and detailed information';
COMMENT ON COLUMN players.basketball_reference_id IS 'Unique player ID from Basketball-Reference (e.g., jamesle01)';
COMMENT ON COLUMN players.height IS 'Player height in feet-inches format (e.g., 6-6)';
COMMENT ON COLUMN players.experience IS 'Years of NBA experience';
COMMENT ON COLUMN players.season_year IS 'NBA season this roster data applies to (e.g., 2024-25)';